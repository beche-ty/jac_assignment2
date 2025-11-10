🤖 RepoDocAgent – AI-Powered Repository Documentation

RepoDocAgent automatically analyzes a GitHub repository, summarizes its structure, extracts code snippets, and generates documentation using AI.

⚡ Features

Clone and scan any GitHub repository.

Identify Python, JavaScript, Jac, Jupyter Notebook, Markdown, and YAML files.

Extract functions, classes, and code context.

Summarize README and installation requirements.

Generate partial analyses and full AI documentation.

Streamlit frontend for easy interaction.

🛠️ Installation

Clone this project:

git clone https://github.com/beche-ty/jac_assignment2
cd codegenius


Set up Python environment:

python -m venv venv
source venv/bin/activate  # Linux / macOS
venv\Scripts\activate     # Windows
pip install -r requirements.txt


Hardcode your  API key (example):
api_key =" xnhebce"



Start the backend server:

jac serve repo_db.jac


Run the Streamlit frontend:

streamlit run frontend.py

🚀 Usage

Open the Streamlit UI in your browser.

Log as a tester account.

Enter the GitHub repository URL you want to analyze.

Click Generate Documentation.

Explore generated documentation, partial analyses, and repository structure.

Download Markdown documentation if needed.

🧩 Supported File Types

.py, .js, .jac

.ipynb, .md, .txt

.yml

📈 AI Documentation

Uses Gemini-2.5-Flash via ByLLM library.

Summarizes repository structure and README.

Extracts code context and generates partial code analyses.

🖥️ Frontend /part1/fe

Built with Streamlit.

Interactive sections for repository info, structure, README summary, and AI-generated docs.
