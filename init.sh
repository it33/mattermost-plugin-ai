#!/bin/bash

team_name="main"
team_display_name="Mattermost AI"
channel_name="ai"
channel_display_name="AI"
user_name="root"
user_password="$(openssl rand -base64 14)"

echo -e "Setting up Mattermost with ...\n Team name: $team_name\n Team display name: $team_display_name\n Channel name: $channel_name\n Channel display name: $channel_display_name"

echo "Initializing Mattermost for demo. This will take about 30 seconds..."

# Download sample local model
wget https://gpt4all.io/models/ggml-gpt4all-j.bin -O models/ggml-gpt4all-j &
echo "The prompt below is a question to answer, a task to complete, or a conversation to respond to; decide which and write an appropriate response.\n### Prompt:\n{{.Input}}\n### Response:" > models/ggml-gpt4all-j.tmpl

sleep 35

docker exec mattermost mmctl --local team create --display-name $team_display_name --name $team_name
docker exec mattermost mmctl --local channel create --team $team_name --display-name "$channel_display_name" --name $channel_name

docker exec mattermost mmctl --local user create --username $user_name --password $user_password --email $user_name@$team_name.com --system-admin --email-verified
docker exec mattermost mmctl --local team users add $team_name $user_name
docker exec mattermost mmctl --local channel users add $team_name:$channel_name $user_name

export MM_ADMIN_USERNAME=$user_name
export MM_ADMIN_PASSWORD=$user_password
export MM_SERVICESETTINGS_SITEURL=http://localhost:8065
export MM_SERVICESETTINGS_ENABLEDEVELOPER=true
make deploy

# Configure plugin
docker exec mattermost bash -c "echo '{\"PluginSettings\":{\"Plugins\":{\"mattermost-ai\":{\"openaicompatibleurl\":\"http://localai:8080\", \"openaicompatiblemodel\":\"ggml-gpt4all-j\",\"llmgenerator\":\"openaicompatible\"}}}}' | mmctl --local config patch /dev/stdin"

echo -e "\n===========================\n\n  THEN LOG IN TO MATTERMOST AT $(gp url 8065)\n\n        username:  $user_name\n        password:  $user_password\n\n  THEN CONFIGURE THE PLUGIN & ENJOY!\n\n"
