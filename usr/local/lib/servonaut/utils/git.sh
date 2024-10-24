#!/bin/bash

setup_github_auth() {
    echo -e "\n🔑 GitHub Authentication Setup\n"
    echo "Please provide your GitHub fine-grained personal access token with the following permissions:"
    echo "- 'Administration' repository permission (write)"
    echo "- 'Webhooks' repository permission (write)"
    echo "You can create a new fine-grained token at https://github.com/settings/tokens?type=beta"

    while true; do
        read -p "Enter your GitHub fine-grained personal access token: " github_token

        # Verify the token
        echo "Verifying token..."
        response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $github_token" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/user)
        http_code=$(echo "$response" | tail -n1)
        response_body=$(echo "$response" | sed '$d')

        if [ "$http_code" -eq 200 ]; then
            echo -e "\n✅ GitHub authentication successful!"
            break
        else
            echo -e "\n❌ GitHub authentication failed. HTTP Status Code: $http_code"
            echo "Response body: $response_body"
            echo "Please check your token and try again."
        fi
    done

    # Store the token securely for later use
    echo "$github_token" >/home/servonaut/.github_token
    chmod 600 /home/servonaut/.github_token
    chown servonaut:servonaut /home/servonaut/.github_token

    # Now ask for the repository URL
    while true; do
        read -p "Enter your GitHub repository SSH URL: " repo_url

        # Validate the repository URL format
        if [[ ! $repo_url =~ ^git@github\.com:.+/.+\.git$ ]]; then
            echo -e "\n❌ Invalid repository URL format. Please use the SSH URL (git@github.com:owner/repo.git)."
            continue
        fi

        # Extract owner and repo from the URL
        owner=$(echo $repo_url | sed -n 's/.*github.com[:/]\(.*\)\/\(.*\)\.git/\1/p')
        repo=$(echo $repo_url | sed -n 's/.*github.com[:/]\(.*\)\/\(.*\)\.git/\2/p')

        # Generate deploy key
        ssh-keygen -t ed25519 -C "servonaut@deployment" -f /home/servonaut/.ssh/id_ed25519 -N ""
        chown servonaut:servonaut /home/servonaut/.ssh/id_ed25519 /home/servonaut/.ssh/id_ed25519.pub
        chmod 600 /home/servonaut/.ssh/id_ed25519
        chmod 644 /home/servonaut/.ssh/id_ed25519.pub
        public_key=$(cat /home/servonaut/.ssh/id_ed25519.pub)

        # Remove any newlines from the public key
        public_key=$(echo "$public_key" | tr -d '\n')

        # Add deploy key to the repository
        echo "Adding deploy key to the repository..."
        echo "Debug: Public key format:"
        echo "$public_key"
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Authorization: Bearer $github_token" \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/$owner/$repo/keys \
            -d '{
        "title": "Servonaut Deploy Key",
        "key": "'"$public_key"'",
        "read_only": false
    }')
        http_code=$(echo "$response" | tail -n1)
        response_body=$(echo "$response" | sed '$d')

        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            echo -e "\n✅ Deploy key added successfully to the repository!"
            break
        else
            echo -e "\n❌ Failed to add deploy key to the repository. HTTP Status Code: $http_code"
            echo "Response body: $response_body"
            echo "Please check your permissions and try again."
            echo -e "If the problem persists, you may need to add the deploy key manually:"
            echo "$public_key"
        fi
    done

    # Store repo URL for later use
    echo "$repo_url" >/home/servonaut/.repo_url
    chmod 600 /home/servonaut/.repo_url
    chown servonaut:servonaut /home/servonaut/.repo_url

    echo -e "\n✅ GitHub authentication and repository setup completed successfully!"
}

setup_github_webhook() {
    local domain_name=$1
    echo -e "\n📡 Setting up GitHub Webhook\n"

    # Generate a secure random token for the webhook
    webhook_token=$(openssl rand -hex 20)

    repo_url=$(cat /home/servonaut/.repo_url)
    owner=$(echo $repo_url | sed -n 's/.*:\(.*\)\/.*/\1/p')
    repo=$(echo $repo_url | sed -n 's/.*\/\(.*\)\.git/\1/p')
    github_token=$(cat /home/servonaut/.github_token)

    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $github_token" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$owner/$repo/hooks \
        -d '{
            "name": "web",
            "active": true,
            "events": ["push"],
            "config": {
                "url": "http://'$domain_name':9000/hooks/servonaut-deploy",
                "content_type": "json",
                "secret": "'$webhook_token'"
            }
        }')

    if [ "$response" -eq 201 ]; then
        echo -e "\n✅ GitHub webhook created successfully!"
        # Save webhook token for later use
        echo "$webhook_token" >/home/servonaut/.webhook_token
        chmod 600 /home/servonaut/.webhook_token
        chown servonaut:servonaut /home/servonaut/.webhook_token
        return 0
    else
        echo -e "\n❌ Failed to create GitHub webhook. Please check your token and try again."
        return 1
    fi
}
