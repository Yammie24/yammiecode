import flet as ft


def main(page: ft.Page):
    page.title = "YammieCode"
    page.padding = 20

    page.add(
        ft.Column(
            [
                ft.Text(
                    "🐍 YammieCode",
                    size=28,
                    weight=ft.FontWeight.BOLD,
                ),
                ft.Text(
                    "Free Python IDE for Android",
                    size=16,
                ),
                ft.Divider(),
                ft.Text(
                    "Python environment ready!",
                    size=18,
                ),
                ft.Text(
                    "Flet is running successfully.",
                ),
                ft.Container(height=20),
                ft.ElevatedButton(
                    "📁 Open Project",
                ),
                ft.ElevatedButton(
                    "📄 New Python File",
                ),
                ft.ElevatedButton(
                    "▶ Run",
                ),
            ],
            spacing=12,
        )
    )


if __name__ == "__main__":
    ft.run(main)
