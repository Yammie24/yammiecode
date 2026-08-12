import '../models/project_file.dart';

class ProjectService {
  static List<ProjectFile> defaultFiles() {
    return [
      ProjectFile(
        name: 'main.py',
        content: '''def main():
    print("Hello from YammieCode!")


if __name__ == "__main__":
    main()
''',
      ),
      ProjectFile(
        name: 'api.py',
        content: '''from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def home():
    return {"message": "Hello from YammieCode!"}
''',
      ),
      ProjectFile(
        name: 'requirements.txt',
        content: '''fastapi
uvicorn
requests
flet
''',
      ),
    ];
  }
}
