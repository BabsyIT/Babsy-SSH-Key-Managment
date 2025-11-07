#!/usr/bin/env python3
"""
Microsoft 365 User Synchronization Script
Syncs IT team users from M365 to user-mapping.json for SSH key management
"""

import json
import sys
import os
import logging
from datetime import datetime
from typing import List, Dict, Optional
import requests

# Logging Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('m365-sync')


class M365UserSync:
    """Handles synchronization of users from Microsoft 365 to local configuration"""

    def __init__(self, config_path: str = '/etc/ssh-key-manager/m365-config.json'):
        """Initialize M365 sync with configuration"""
        self.config = self._load_config(config_path)
        self.access_token = None

    def _load_config(self, config_path: str) -> Dict:
        """Load M365 configuration from file"""
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            logger.info(f"Configuration loaded from {config_path}")
            return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {config_path}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in configuration: {e}")
            sys.exit(1)

    def authenticate(self) -> bool:
        """Authenticate with Microsoft Graph API using client credentials flow"""
        tenant_id = self.config.get('tenant_id')
        client_id = self.config.get('client_id')
        client_secret = self.config.get('client_secret')

        if not all([tenant_id, client_id, client_secret]):
            logger.error("Missing required authentication parameters")
            return False

        token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"

        data = {
            'grant_type': 'client_credentials',
            'client_id': client_id,
            'client_secret': client_secret,
            'scope': 'https://graph.microsoft.com/.default'
        }

        try:
            response = requests.post(token_url, data=data, timeout=30)
            response.raise_for_status()

            token_data = response.json()
            self.access_token = token_data.get('access_token')

            if self.access_token:
                logger.info("Successfully authenticated with Microsoft Graph API")
                return True
            else:
                logger.error("No access token received")
                return False

        except requests.exceptions.RequestException as e:
            logger.error(f"Authentication failed: {e}")
            return False

    def _make_graph_request(self, endpoint: str) -> Optional[Dict]:
        """Make a request to Microsoft Graph API"""
        if not self.access_token:
            logger.error("Not authenticated. Call authenticate() first.")
            return None

        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }

        url = f"https://graph.microsoft.com/v1.0{endpoint}"

        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Graph API request failed for {endpoint}: {e}")
            return None

    def get_group_members(self, group_name: str) -> List[Dict]:
        """Get members of a specific group by name"""
        # First, find the group by name
        search_endpoint = f"/groups?$filter=displayName eq '{group_name}'"
        group_data = self._make_graph_request(search_endpoint)

        if not group_data or not group_data.get('value'):
            logger.error(f"Group '{group_name}' not found")
            return []

        group_id = group_data['value'][0]['id']
        logger.info(f"Found group '{group_name}' with ID: {group_id}")

        # Get group members with extended properties
        members_endpoint = f"/groups/{group_id}/members?$select=id,displayName,userPrincipalName,mail,givenName,surname,extensionAttributes"
        members_data = self._make_graph_request(members_endpoint)

        if not members_data:
            logger.error("Failed to retrieve group members")
            return []

        members = members_data.get('value', [])
        logger.info(f"Retrieved {len(members)} members from group '{group_name}'")

        return members

    def get_user_github_username(self, user_id: str) -> Optional[str]:
        """Get GitHub username from user's custom attribute or extension attribute"""
        # Try to get user details with extension attributes
        user_endpoint = f"/users/{user_id}"
        user_data = self._make_graph_request(user_endpoint)

        if not user_data:
            return None

        # Check various possible locations for GitHub username
        github_field = self.config.get('github_username_field', 'extensionAttribute1')

        # Try extension attributes (these are typically extensionAttribute1-15)
        github_username = user_data.get(github_field)

        if not github_username:
            # Try to get from onPremisesExtensionAttributes
            ext_attrs = user_data.get('onPremisesExtensionAttributes', {})
            github_username = ext_attrs.get(github_field)

        return github_username

    def transform_user_to_config(self, m365_user: Dict) -> Optional[Dict]:
        """Transform M365 user data to our user-mapping.json format"""
        user_id = m365_user.get('id')
        display_name = m365_user.get('displayName', '')
        upn = m365_user.get('userPrincipalName', '')

        # Extract local username from UPN (part before @)
        local_user = upn.split('@')[0] if upn else ''
        local_user = local_user.lower().replace('.', '')  # Clean username

        # Get GitHub username from custom field
        github_username = self.get_user_github_username(user_id)

        if not github_username:
            logger.warning(f"No GitHub username found for {display_name} ({upn})")
            return None

        # Get sudo and groups config from M365 or use defaults
        sudo_access = self.config.get('default_sudo_access', 'limited')
        groups = self.config.get('default_groups', ['users', 'sudo'])
        sudo_commands = self.config.get('default_sudo_commands', [
            '/usr/bin/systemctl restart *',
            '/usr/bin/systemctl reload *',
            '/usr/bin/systemctl status *',
            '/usr/bin/docker *',
            '/usr/bin/journalctl *'
        ])

        user_config = {
            'github_user': github_username,
            'local_user': local_user,
            'full_name': display_name,
            'sudo_access': sudo_access,
            'groups': groups,
            'm365_upn': upn,
            'm365_sync': True,
            'last_synced': datetime.utcnow().isoformat()
        }

        if sudo_access == 'limited':
            user_config['sudo_commands'] = sudo_commands

        return user_config

    def sync_users(self) -> bool:
        """Main sync function: fetch from M365 and update user-mapping.json"""
        logger.info("Starting M365 user synchronization...")

        # Authenticate
        if not self.authenticate():
            logger.error("Authentication failed, cannot sync users")
            return False

        # Get IT team members
        it_group_name = self.config.get('it_group_name', 'IT-Team')
        members = self.get_group_members(it_group_name)

        if not members:
            logger.warning("No members found in IT group")
            return False

        # Transform users
        synced_users = []
        for member in members:
            user_config = self.transform_user_to_config(member)
            if user_config:
                synced_users.append(user_config)
                logger.info(f"Synced: {user_config['full_name']} -> {user_config['local_user']} (GitHub: {user_config['github_user']})")

        # Load existing user-mapping.json
        mapping_file = self.config.get('user_mapping_file', '/root/Babsy-SSH-Key-Managment/config/user-mapping.json')

        try:
            with open(mapping_file, 'r') as f:
                existing_config = json.load(f)
        except FileNotFoundError:
            logger.info("No existing user-mapping.json found, creating new one")
            existing_config = {
                'users': [],
                'config': {
                    'default_shell': '/bin/bash',
                    'default_group': 'users',
                    'user_home_base': '/home'
                }
            }

        # Merge: Keep manually added users (those without m365_sync flag)
        manual_users = [u for u in existing_config.get('users', []) if not u.get('m365_sync', False)]

        # Combine manual and synced users
        all_users = manual_users + synced_users

        # Update configuration
        existing_config['users'] = all_users
        existing_config['_m365_sync_info'] = {
            'last_sync': datetime.utcnow().isoformat(),
            'synced_users_count': len(synced_users),
            'manual_users_count': len(manual_users),
            'it_group': it_group_name
        }

        # Write back to file
        try:
            # Create backup first
            if os.path.exists(mapping_file):
                backup_file = f"{mapping_file}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                os.rename(mapping_file, backup_file)
                logger.info(f"Created backup: {backup_file}")

            with open(mapping_file, 'w') as f:
                json.dump(existing_config, f, indent=2)

            logger.info(f"Successfully updated {mapping_file}")
            logger.info(f"Total users: {len(all_users)} (Manual: {len(manual_users)}, M365: {len(synced_users)})")

            return True

        except Exception as e:
            logger.error(f"Failed to write user-mapping.json: {e}")
            return False


def main():
    """Main entry point"""
    # Check for config file path from environment or use default
    config_path = os.environ.get('M365_CONFIG_PATH', '/etc/ssh-key-manager/m365-config.json')

    syncer = M365UserSync(config_path)

    if syncer.sync_users():
        logger.info("User synchronization completed successfully")
        sys.exit(0)
    else:
        logger.error("User synchronization failed")
        sys.exit(1)


if __name__ == '__main__':
    main()
