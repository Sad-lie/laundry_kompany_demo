#!/bin/bash
# Deployment script for Laundry Kampany Demo

# Set environment variables
export PORT=4000
export MIX_ENV=prod
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-laundry2024}"
export WHATSAPP_PHONE_NUMBER_ID="${WHATSAPP_PHONE_NUMBER_ID}"
export WHATSAPP_ACCESS_TOKEN="${WHATSAPP_ACCESS_TOKEN}"
export WHATSAPP_VERIFY_TOKEN="${WHATSAPP_VERIFY_TOKEN:-laundry_kompany_demo_token}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE:-$(mix phx.gen.secret)}"

echo "Starting Laundry Kampany Demo..."
echo "Admin password: $ADMIN_PASSWORD"
echo "Port: $PORT"

# Run the release
cd /home/laundry_kompany_demo
./bin/laundry_kompany_demo start
