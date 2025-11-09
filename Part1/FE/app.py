import streamlit as st
import requests

BACKEND_URL = "http://localhost:8000"

st.set_page_config(page_title="RepoDocAgent", page_icon="📘", layout="wide")
st.title("🤖 RepoDocAgent – AI-Powered Repository Documentation")

# --- Authentication ---
if "token" not in st.session_state:
    st.session_state.token = None

if not st.session_state.token:
    st.subheader("🔐 Login Required")

    with st.form("login_form"):
        email = st.text_input("Email", "test@mail.com")
        password = st.text_input("Password", "password", type="password")
        submitted = st.form_submit_button("Login")

        if submitted:
            try:
                res = requests.post(
                    f"{BACKEND_URL}/user/login",
                    json={"email": email, "password": password}
                )

                if res.status_code == 200:
                    st.session_state.token = res.json()["token"]
                    st.success("✅ Logged in successfully!")
                    st.rerun()

                elif res.status_code == 404:
                    st.warning("User not found — registering automatically...")
                    reg = requests.post(
                        f"{BACKEND_URL}/user/register",
                        json={"email": email, "password": password}
                    )
                    if reg.status_code == 201:
                        st.info("✅ User registered. Please click Login again.")
                    else:
                        st.error("❌ Registration failed.")

                else:
                    st.error("❌ Login failed. Check credentials or server status.")

            except requests.exceptions.RequestException as e:
                st.error(f"🚨 Connection error: {e}")

else:
    st.success("✅ Authenticated successfully!")
    st.markdown("---")
    st.header("📂 Repository Analyzer")

    repo_url = st.text_input("🔗 Enter GitHub Repository URL:")

    if st.button("🚀 Generate Documentation"):
        if not repo_url.strip():
            st.warning("⚠️ Please enter a repository URL first.")
        else:
            with st.spinner("🧠 Processing repository..."):
                try:
                    res = requests.post(
                        f"{BACKEND_URL}/walker/RepoDocAgent",
                        json={"repo_url": repo_url},
                        headers={"Authorization": f"Bearer {st.session_state.token}"}
                    )

                    if res.status_code == 200:
                        response = res.json()

                        # ✅ Adjusted to match Jac backend’s report structure
                        reports = response.get("reports", [])
                        if not reports:
                            st.error("⚠️ No reports returned from backend.")
                        else:
                            report = reports[0]

                            if report.get("status") == "success":
                                st.success("✅ Repository Analysis Complete!")

                                # ---- Sections ----
                                with st.expander("📘 Repository Info", expanded=True):
                                    st.write(f"**URL:** {report.get('repo_url', 'N/A')}")
                                    st.write(f"**Status:** {report.get('status', 'N/A')}")

                                with st.expander("🗺️ Repository Structure"):
                                    st.code(report.get("structure", "No structure found."))

                                with st.expander("📖 README Summary"):
                                    st.write(report.get("readme_summary", "No README summary available."))

                                with st.expander("🧠 AI Analysis Plan"):
                                    st.write(report.get("analysis_summary", "No analysis plan generated."))

                                with st.expander("🔍 Partial Code Analyses"):
                                    analyses = report.get("partial_analyses", [])
                                    if analyses:
                                        for i, snippet in enumerate(analyses, 1):
                                            st.markdown(f"**Analysis {i}:**")
                                            st.code(snippet)
                                    else:
                                        st.write("No individual code analyses available.")

                                with st.expander("🧾 Documentation Preview", expanded=True):
                                    doc_preview = report.get("docs_preview", "")
                                    if doc_preview:
                                        st.text_area("Generated Documentation", doc_preview, height=400)
                                        st.download_button(
                                            label="⬇️ Download Markdown",
                                            data=doc_preview,
                                            file_name="repo_documentation.md",
                                            mime="text/markdown"
                                        )
                                    else:
                                        st.warning("No documentation preview available.")

                            else:
                                st.error(f"❌ {report.get('message', 'Repository clone failed.')}")
                    else:
                        st.error(f"❌ Backend Error {res.status_code}: {res.text}")

                except requests.exceptions.RequestException as e:
                    st.error(f"🚨 Connection Error: {e}")

    # --- Logout Button ---
    st.markdown("---")
    if st.button("🔒 Logout"):
        st.session_state.token = None
        st.success("Logged out successfully!")
        st.rerun()
