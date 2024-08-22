#!/bin/bash

# Set your API token and Account ID
API_TOKEN="your_api_token"
ACCOUNT_ID="your_account_id"

# ANSI escape codes for colors
RED='\033[91m'
BLUE='\033[94m'
GREEN='\033[92m'
RESET='\033[0m'  # Reset color

# Function to fetch a worker script
fetch_worker_script() {
    SCRIPT_URL="$1"
    RESPONSE=$(curl -s "$SCRIPT_URL")
    if [ "$?" -eq 0 ]; then
        echo "$RESPONSE"
    else
        echo -e "${RED}Failed to fetch worker script.${RESET}"
        return 1
    fi
}

# Function to create a KV namespace
create_kv_namespace() {
    KV_NAMESPACE_NAME="$1"
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/storage/kv/namespaces" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"title\":\"$KV_NAMESPACE_NAME\"}")
    echo "$RESPONSE" | grep -q '"success":true'
    if [ "$?" -eq 0 ]; then
        NAMESPACE_ID=$(echo "$RESPONSE" | jq -r '.result.id')
        echo -e "${GREEN}KV namespace \"$KV_NAMESPACE_NAME\" created successfully with ID: $NAMESPACE_ID${RESET}"
        echo "$NAMESPACE_ID"
    else
        echo -e "${RED}Failed to create KV namespace.${RESET}"
        return 1
    fi
}

# Function to create or update a Cloudflare Worker
create_worker() {
    WORKER_NAME="$1"
    SCRIPT="$2"
    KV_NAMESPACE_ID="$3"
    VARIABLE_NAME="$4"
    
    # Prepare metadata with bindings
    METADATA=$(cat <<EOF
{
    "main_module": "worker.js",
    "type": "esm",
    "bindings": [
        {
            "name": "$VARIABLE_NAME",
            "namespace_id": "$KV_NAMESPACE_ID",
            "type": "kv_namespace"
        }
    ]
}
EOF
)
    
    # Use curl to upload the worker script
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts/$WORKER_NAME" \
        -H "Authorization: Bearer $API_TOKEN" \
        -F "metadata=@-;type=application/json" <<< "$METADATA" \
        -F "worker.js=@$SCRIPT;type=application/javascript+module")
    echo "$RESPONSE" | grep -q '"success":true'
    if [ "$?" -eq 0 ]; then
        if [ -n "$KV_NAMESPACE_ID" ] && [ -n "$VARIABLE_NAME" ]; then
            echo -e "${GREEN}Worker $WORKER_NAME created/updated successfully and bound to KV namespace with variable name \"$VARIABLE_NAME\".${RESET}"
        else
            echo -e "${GREEN}Worker $WORKER_NAME created/updated successfully without KV namespace binding.${RESET}"
        fi
        return 0
    else
        echo -e "${RED}Failed to create/update worker.${RESET}"
        return 1
    fi
}

# Function to retrieve the workers.dev subdomain for the Cloudflare account
get_workers_dev_subdomain() {
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/subdomain" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    echo "$RESPONSE" | grep -q '"success":true'
    if [ "$?" -eq 0 ]; then
        SUBDOMAIN=$(echo "$RESPONSE" | jq -r '.result.subdomain')
        echo -e "${GREEN}Workers.dev subdomain retrieved: $SUBDOMAIN${RESET}"
        echo "$SUBDOMAIN"
    else
        echo -e "${RED}Failed to retrieve workers.dev subdomain.${RESET}"
        return 1
    fi
}

# Function to generate the default workers.dev URL for the worker
generate_worker_link() {
    WORKER_NAME="$1"
    SUBDOMAIN="$2"
    echo "https://${WORKER_NAME}.${SUBDOMAIN}.workers.dev"
}

# Function to publish the worker on the workers.dev subdomain
publish_worker_on_workers_dev() {
    WORKER_NAME="$1"
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts/$WORKER_NAME/subdomain" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"enabled":true}')
    echo "$RESPONSE" | grep -q '"success":true'
    if [ "$?" -eq 0 ]; then
        echo -e "${GREEN}Worker \"$WORKER_NAME\" published on workers.dev subdomain successfully.${RESET}"
        return 0
    else
        echo -e "${RED}Failed to publish worker on workers.dev subdomain.${RESET}"
        return 1
    fi
}

# Function to list all Cloudflare Workers
list_workers() {
    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    echo "$RESPONSE" | grep -q '"success":true'
    if [ "$?" -eq 0 ]; then
        echo -e "${GREEN}List of workers:${RESET}"
        echo "$RESPONSE" | jq -r '.result[].id'
        return 0
    else
        echo -e "${RED}Failed to list workers.${RESET}"
        return 1
    fi
}

# Function to delete a Cloudflare Worker
delete_worker() {
    WORKER_NAME="$1"
    RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts/$WORKER_NAME" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    echo "$RESPONSE" | grep -q '"success":true'
    if [ "$?" -eq 0 ]; then
        echo -e "${GREEN}Worker \"$WORKER_NAME\" deleted successfully.${RESET}"
        return 0
    else
        echo -e "${RED}Failed to delete worker.${RESET}"
        return 1
    fi
}

# Main function to run the script
main() {
    # Collecting information from the user
    read -p "Enter your Cloudflare API token: " API_TOKEN
    read -p "Enter your Cloudflare account ID: " ACCOUNT_ID
    
    while true; do
        # Display channel names with colors
        echo -e "${RED}YOUTUBE: KOLANDONE${RESET}"
        echo -e "${BLUE}TELEGRAM: KOLANDJS${RESET}"

        # Ask the user what action they want to perform
        echo -e "\nChoose an action:"
        echo "1: List Workers"
        echo "2: Create Worker"
        echo "3: Delete Worker"
        echo "Type 'exit' to quit the program."
        read -p "Enter the number of the action you want to perform or 'exit': " ACTION

        case $ACTION in
            1)
                list_workers
                ;;
            2)
                read -p "Enter the desired worker name: " WORKER_NAME
                read -p "Do you want to create a KV namespace? (yes/no): " CREATE_KV
                KV_NAMESPACE_ID=""
                VARIABLE_NAME=""
                if [ "$CREATE_KV" == "yes" ]; then
                    read -p "Enter the desired KV namespace name: " KV_NAMESPACE_NAME
                    read -p "Enter the desired variable name for the KV namespace binding: " VARIABLE_NAME
                    KV_NAMESPACE_ID=$(create_kv_namespace "$KV_NAMESPACE_NAME")
                    if [ -z "$KV_NAMESPACE_ID" ]; then
                        echo -e "${RED}Failed to create KV namespace.${RESET}"
                        continue
                    fi
                fi
                read -p "Enter the URL to fetch the worker script: " SCRIPT_URL
                SCRIPT_CONTENT=$(fetch_worker_script "$SCRIPT_URL")
                if [ -n "$SCRIPT_CONTENT" ]; then
                    SUBDOMAIN=$(get_workers_dev_subdomain)
                    if [ -n "$SUBDOMAIN" ]; then
                        if create_worker "$WORKER_NAME" "$SCRIPT_CONTENT" "$KV_NAMESPACE_ID" "$VARIABLE_NAME"; then
                            if publish_worker_on_workers_dev "$WORKER_NAME"; then
                                WORKER_LINK=$(generate_worker_link "$WORKER_NAME" "$SUBDOMAIN")
                                echo -e "${GREEN}You can visit your worker at: $WORKER_LINK${RESET}"
                            else
                                echo -e "${RED}Failed to publish the worker on workers.dev subdomain.${RESET}"
                            fi
                        else
                            echo -e "${RED}Failed to create the worker.${RESET}"
                        fi
                    else
                        echo -e "${RED}Failed to retrieve workers.dev subdomain.${RESET}"
                    fi
                else
                    echo -e "${RED}Failed to fetch the worker script.${RESET}"
                fi
                ;;
            3)
                read -p "Enter the name of the worker to delete: " WORKER_NAME
                                delete_worker "$WORKER_NAME"
                ;;
            exit)
                echo "Exiting the program."
                break
                ;;
            *)
                echo -e "${RED}Invalid action selected.${RESET}"
                ;;
        esac
    done
}

# Run the main function
main
