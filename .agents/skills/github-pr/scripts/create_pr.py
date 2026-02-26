import os
import sys
import json
import argparse
import subprocess
import urllib.request
import urllib.parse
import urllib.error

def get_repo_info():
    """Extracts owner and repo string from local git configuration."""
    try:
        remote = subprocess.check_output(['git', 'config', '--get', 'remote.origin.url']).decode('utf-8').strip()
        if 'github.com' not in remote:
            raise ValueError(f"Origin '{remote}' is not a recognized github.com URL")
        
        # Works for both HTTPS (https://github.com/owner/repo.git) and SSH (git@github.com:owner/repo.git)
        parts = remote.replace('.git', '').split('github.com')[-1]
        if parts.startswith(':') or parts.startswith('/'):
            parts = parts[1:]
        owner, repo = parts.split('/')
        return owner, repo
    except Exception as e:
        print(f"Error getting repository information: {str(e)}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Create a GitHub Pull Request via the GitHub REST API.")
    parser.add_argument("--source", required=True, help="Source feature branch (head).")
    parser.add_argument("--target", required=True, help="Target merge branch (base).")
    parser.add_argument("--title", required=True, help="Title of the PR.")
    parser.add_argument("--description", required=True, help="Markdown description text.")
    parser.add_argument("--checklist", required=True, help="Security checklist markdown.")
    parser.add_argument("--draft", action="store_true", help="Submit as a Draft PR.")
    args = parser.parse_args()

    owner, repo = get_repo_info()
    token = os.environ.get("GITHUB_TOKEN")
    
    if not token:
        print("⚠️ GITHUB_TOKEN not found. Falling back to Local Link Mode.")
        encoded_title = urllib.parse.quote(args.title)
        encoded_body = urllib.parse.quote(f"{args.description}\n\n{args.checklist}")
        link = f"https://github.com/{owner}/{repo}/compare/{args.target}...{args.source}?expand=1&title={encoded_title}&body={encoded_body}"
        print("✅ Pull Request link generated successfully!")
        print(f"👉 Automatically Pre-filled URL: {link}")
        sys.exit(0)

    url = f"https://api.github.com/repos/{owner}/{repo}/pulls"
    
    data = {
        "title": args.title,
        "body": f"{args.description}\n\n{args.checklist}",
        "head": args.source,
        "base": args.target,
        "draft": args.draft
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json"
    }
    
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            print("✅ Pull Request created successfully!")
            print(f"👉 URL: {res_data.get('html_url')}")
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode('utf-8')
        print(f"❌ Failed to create PR: HTTP {e.code} {e.reason}")
        print(err_msg)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
