from __future__ import annotations

import asyncio
import hashlib
import html
import os
import re
from datetime import UTC, datetime
from email.utils import parsedate_to_datetime
from urllib.parse import urlencode
from xml.etree import ElementTree

import httpx

from .schemas import FashionNewsPost, FashionNewsResponse, NewsSourceStatus


_CATEGORY_QUERIES = {
    "all": "fashion trends",
    "y2k": "Y2K fashion",
    "gothic": "gothic fashion",
    "alternative": "alternative fashion",
    "formal": "formal fashion",
    "casual": "casual fashion",
    "wedding": "wedding fashion",
    "streetwear": "streetwear fashion",
    "vintage": "vintage fashion",
}


class FashionNewsService:
    async def fetch(self, category: str, limit: int = 16) -> FashionNewsResponse:
        normalized = category.strip().lower()
        query = _CATEGORY_QUERIES.get(normalized, _CATEGORY_QUERIES["all"])
        reddit_token = os.getenv("REDDIT_ACCESS_TOKEN", "").strip()

        async with httpx.AsyncClient(
            timeout=httpx.Timeout(8.0),
            follow_redirects=True,
            headers={"User-Agent": "Stylorista-AI/0.1 fashion-news-feed"},
        ) as client:
            tasks = [
                self._fetch_gdelt(client, query, normalized, limit),
                self._fetch_google_news(client, query, normalized, limit),
            ]
            if reddit_token:
                tasks.append(
                    self._fetch_reddit(
                        client, query, normalized, reddit_token, limit
                    )
                )
            results = await asyncio.gather(*tasks, return_exceptions=True)

        gdelt_items = self._successful_items(results[0])
        google_items = self._successful_items(results[1])
        reddit_items = (
            self._successful_items(results[2])
            if reddit_token and len(results) > 2
            else []
        )
        merged = self._merge(gdelt_items, google_items, reddit_items, limit=limit)
        if not merged:
            merged = self._fallback_posts(normalized)

        return FashionNewsResponse(
            category=normalized,
            fetched_at=datetime.now(UTC),
            items=merged,
            sources=[
                NewsSourceStatus(
                    name="Google News",
                    connected=bool(google_items),
                    note=(
                        "Live RSS stories"
                        if google_items
                        else "Temporarily unavailable; fallback feed is shown"
                    ),
                ),
                NewsSourceStatus(
                    name="Global publishers",
                    connected=bool(gdelt_items),
                    note=(
                        "Live via GDELT"
                        if gdelt_items
                        else "GDELT is temporarily unavailable"
                    ),
                ),
                NewsSourceStatus(
                    name="Reddit",
                    connected=bool(reddit_items),
                    note=(
                        "Connected with approved OAuth access"
                        if reddit_items
                        else "Requires REDDIT_ACCESS_TOKEN and approved API access"
                    ),
                ),
                NewsSourceStatus(
                    name="Facebook + Instagram",
                    connected=False,
                    note="Requires approved Meta app access and eligible accounts",
                ),
            ],
        )

    async def _fetch_gdelt(
        self,
        client: httpx.AsyncClient,
        query: str,
        category: str,
        limit: int,
    ) -> list[FashionNewsPost]:
        response = await client.get(
            "https://api.gdeltproject.org/api/v2/doc/doc",
            params={
                "query": f'"{query}"',
                "mode": "artlist",
                "maxrecords": min(limit, 50),
                "timespan": "1month",
                "sort": "datedesc",
                "format": "json",
            },
        )
        response.raise_for_status()
        payload = response.json()
        posts: list[FashionNewsPost] = []
        for article in payload.get("articles", []):
            url = str(article.get("url", "")).strip()
            title = str(article.get("title", "")).strip()
            if not url or not title:
                continue
            publisher = str(article.get("domain", "Global publisher")).strip()
            posts.append(
                self._post(
                    title=title,
                    summary=f"Explore this {category} fashion story from {publisher}.",
                    url=url,
                    image_url=self._safe_image(article.get("socialimage")),
                    publisher=publisher,
                    platform="Global News",
                    category=category,
                    published_at=self._parse_gdelt_date(article.get("seendate")),
                )
            )
        return posts

    async def _fetch_google_news(
        self,
        client: httpx.AsyncClient,
        query: str,
        category: str,
        limit: int,
    ) -> list[FashionNewsPost]:
        response = await client.get(
            "https://news.google.com/rss/search",
            params={
                "q": query,
                "hl": "en-PH",
                "gl": "PH",
                "ceid": "PH:en",
            },
        )
        response.raise_for_status()
        root = ElementTree.fromstring(response.content)
        posts: list[FashionNewsPost] = []
        for item in root.findall("./channel/item")[:limit]:
            title = (item.findtext("title") or "").strip()
            url = (item.findtext("link") or "").strip()
            if not title or not url:
                continue
            source_node = item.find("source")
            publisher = (
                (source_node.text or "Google News").strip()
                if source_node is not None
                else "Google News"
            )
            summary = self._clean_summary(item.findtext("description") or "")
            posts.append(
                self._post(
                    title=title,
                    summary=summary
                    or f"Open this {category} fashion story in Google News.",
                    url=url,
                    image_url=None,
                    publisher=publisher,
                    platform="Google News",
                    category=category,
                    published_at=self._parse_rss_date(item.findtext("pubDate")),
                )
            )
        return posts

    async def _fetch_reddit(
        self,
        client: httpx.AsyncClient,
        query: str,
        category: str,
        token: str,
        limit: int,
    ) -> list[FashionNewsPost]:
        response = await client.get(
            "https://oauth.reddit.com/search",
            params={"q": query, "sort": "new", "limit": min(limit, 25)},
            headers={"Authorization": f"Bearer {token}"},
        )
        response.raise_for_status()
        posts: list[FashionNewsPost] = []
        for child in response.json().get("data", {}).get("children", []):
            data = child.get("data", {})
            permalink = str(data.get("permalink", "")).strip()
            title = str(data.get("title", "")).strip()
            if not permalink or not title:
                continue
            preview = data.get("preview", {}).get("images", [])
            image_url = None
            if preview:
                image_url = html.unescape(
                    str(preview[0].get("source", {}).get("url", ""))
                )
            posts.append(
                self._post(
                    title=title,
                    summary=self._clean_summary(str(data.get("selftext", "")))
                    or "Join this fashion conversation on Reddit.",
                    url=f"https://www.reddit.com{permalink}",
                    image_url=self._safe_image(image_url),
                    publisher=f"r/{data.get('subreddit', 'fashion')}",
                    platform="Reddit",
                    category=category,
                    published_at=datetime.fromtimestamp(
                        float(data.get("created_utc", 0)), tz=UTC
                    ),
                    like_count=max(int(data.get("score", 0)), 0),
                    comment_count=max(int(data.get("num_comments", 0)), 0),
                )
            )
        return posts

    def _post(
        self,
        *,
        title: str,
        summary: str,
        url: str,
        image_url: str | None,
        publisher: str,
        platform: str,
        category: str,
        published_at: datetime,
        like_count: int = 0,
        comment_count: int = 0,
    ) -> FashionNewsPost:
        digest = hashlib.sha256(url.encode("utf-8")).hexdigest()
        return FashionNewsPost(
            id=digest[:16],
            title=title[:220],
            summary=summary[:360],
            url=url,
            image_url=image_url,
            publisher=publisher[:80],
            platform=platform,
            category=category,
            published_at=published_at,
            like_count=like_count,
            comment_count=comment_count,
        )

    def _merge(
        self,
        *groups: list[FashionNewsPost],
        limit: int,
    ) -> list[FashionNewsPost]:
        unique: dict[str, FashionNewsPost] = {}
        for index in range(max((len(group) for group in groups), default=0)):
            for group in groups:
                if index >= len(group):
                    continue
                post = group[index]
                key = re.sub(r"\W+", "", post.title.lower())[:120]
                unique.setdefault(key, post)
                if len(unique) >= limit:
                    return list(unique.values())
        return list(unique.values())

    def _fallback_posts(self, category: str) -> list[FashionNewsPost]:
        label = "fashion" if category == "all" else category
        titles = [
            f"Explore the latest {label} fashion coverage",
            f"How creators are styling {label} looks",
            f"New ideas and inspiration for {label} wardrobes",
            f"Discover current conversations about {label} style",
        ]
        search_url = "https://news.google.com/search?" + urlencode(
            {
                "q": f"{label} fashion",
                "hl": "en-PH",
                "gl": "PH",
                "ceid": "PH:en",
            }
        )
        return [
            self._post(
                title=title,
                summary=(
                    "Live sources are temporarily unavailable. Open Google News "
                    "to continue exploring this fashion category."
                ),
                url=search_url,
                image_url=None,
                publisher="Stylorista discovery",
                platform="Google News",
                category=category,
                published_at=datetime.now(UTC),
            )
            for title in titles
        ]

    @staticmethod
    def _successful_items(result: object) -> list[FashionNewsPost]:
        return result if isinstance(result, list) else []

    @staticmethod
    def _clean_summary(value: str) -> str:
        no_tags = re.sub(r"<[^>]+>", " ", html.unescape(value))
        return re.sub(r"\s+", " ", no_tags).strip()

    @staticmethod
    def _safe_image(value: object) -> str | None:
        image_url = str(value or "").strip()
        return image_url if image_url.startswith("https://") else None

    @staticmethod
    def _parse_gdelt_date(value: object) -> datetime:
        try:
            return datetime.strptime(str(value), "%Y%m%dT%H%M%SZ").replace(tzinfo=UTC)
        except ValueError:
            return datetime.now(UTC)

    @staticmethod
    def _parse_rss_date(value: str | None) -> datetime:
        try:
            parsed = parsedate_to_datetime(value or "")
            return parsed.astimezone(UTC)
        except (TypeError, ValueError):
            return datetime.now(UTC)
