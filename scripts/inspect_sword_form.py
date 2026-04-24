from __future__ import annotations

from bs4 import BeautifulSoup
import httpx


URL = "https://swordsolutions.com/inspections/"


def main() -> None:
    response = httpx.get(URL, timeout=30.0, follow_redirects=True)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "html.parser")
    forms = soup.find_all("form")

    print(f"Fetched: {response.url}")
    print(f"Found {len(forms)} form(s)")
    print()

    for index, form in enumerate(forms, start=1):
        print(f"=== Form {index} ===")
        print(f"action={form.get('action')}")
        print(f"method={form.get('method')}")
        print()

        print("-- inputs --")
        for element in form.find_all("input"):
            print(
                {
                    "type": element.get("type"),
                    "name": element.get("name"),
                    "id": element.get("id"),
                    "value": element.get("value"),
                }
            )

        print()
        print("-- selects --")
        for select in form.find_all("select"):
            print(
                {
                    "name": select.get("name"),
                    "id": select.get("id"),
                }
            )
            options = []
            for option in select.find_all("option"):
                options.append(
                    {
                        "value": option.get("value"),
                        "label": option.get_text(" ", strip=True),
                    }
                )
            print(options)
            print()

        print("-- buttons --")
        for button in form.find_all("button"):
            print(
                {
                    "type": button.get("type"),
                    "name": button.get("name"),
                    "id": button.get("id"),
                    "text": button.get_text(" ", strip=True),
                }
            )
        print()


if __name__ == "__main__":
    main()

