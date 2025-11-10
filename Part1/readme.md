## 🤖 RepoDocAgent – AI-Powered Repository Documentation

RepoDocAgent automatically analyzes a GitHub repository, summarizes its structure, extracts code snippets, and generates documentation using AI.

The project integrates a Jac-based backend with a Streamlit frontend for interactive use.


## ⚡ Features

Clone and scan any GitHub repository.

Identify Python, JavaScript, Jac, Jupyter Notebook, Markdown, and YAML files.

Extract functions, classes, and code context.

Summarize README and installation requirements.

Generate partial analyses and full AI documentation.

Streamlit frontend for easy interaction.

🛠️ Installation

##Clone this project:
```bash
git clone https://github.com/beche-ty/jac_assignment2
cd codegenius


##Set up Python environment:

python -m venv venv
source venv/bin/activate  # Linux / macOS
venv\Scripts\activate     # Windows
pip install -r requirements.txt



##Hardcode your  API key (example):
api_key =" xnhebce"



##Start the backend server:
``` bash
jac serve repo_db.jac



##Run the Streamlit frontend:
streamlit run frontend.py


## 🚀 Usage

Open the Streamlit UI in your browser.

Log as a tester account.

Enter the GitHub repository URL you want to analyze.

Click Generate Documentation.

Explore generated documentation, partial analyses, and repository structure.

Download Markdown documentation if needed.

## 🧩 Supported File Types

.py, .js, .jac

.ipynb, .md, .txt

.yml

## 📈 AI Documentation

Uses Gemini-2.5-Flash via ByLLM library.

Summarizes repository structure and README.

Extracts code context and generates partial code analyses.

##🖥️ Frontend /part1/fe

Built with Streamlit.

Interactive sections for repository info, structure, README summary, and AI-generated docs.

## Challenges Faced

During development, one major challenge was API integration using environment variables:

Fetching the API key from .env caused syntax and type issues in Jac.

Ensuring the key is securely available in both backend and frontend without exposing it in code required careful handling.

## How to Improve

Implement a Jac-native loader for .env variables.

Centralize API key management for all nodes requiring AI access.

Include checks for missing or invalid API keys before making API calls.

Document setup instructions clearly for new developers.

## Future Enhancements

Full AI-generated analysis summary instead of code display

Better error handling and validation for repository cloning

Support for additional file types and larger repositorie



