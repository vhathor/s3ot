
Setup 

-- Update from Vishal in Github editor
-- Another update in Snowflake editor

# Step-by-Step Guide: Connecting Two Snowflake Accounts to One GitHub Repository

This guide will help you connect **ACCOUNT_A** and **ACCOUNT_B** to the GitHub repository `https://github.com/vhathor/s3ot/tree/main` and synchronize the `snow_github.sql` file between both accounts.

## Prerequisites

- Administrative access to both Snowflake accounts (ACCOUNTADMIN role)
- Access to the GitHub repository
- GitHub account with appropriate permissions

## Part 1: GitHub Setup

### Step 1: Create GitHub Personal Access Token

1. **Log into GitHub** and navigate to your profile settings
2. **Go to Developer Settings**:
   - Click your profile picture → Settings
   - Scroll down to "Developer settings" on the left panel
3. **Create Personal Access Token**:
   - Click "Personal access tokens" → "Tokens (classic)"
   - Click "Generate new token" → "Generate new token (classic)"
   - **Set token name**: `Snowflake-Integration-Token`
   - **Set expiration**: 6-12 months
   - **Select scopes**: Check "repo" (Full control of private repositories)
   - Click "Generate token"
4. **Save the token** - Copy and store it securely (you won't see it again)

## Part 2: Snowflake Account Setup (Repeat for ACCOUNT_A and ACCOUNT_B)

### Step 2: Create Database and Schema Structure

```sql
-- Execute in both ACCOUNT_A and ACCOUNT_B
USE ROLE ACCOUNTADMIN;

-- Create database for Git integration
CREATE OR REPLACE DATABASE git_integration_db;

-- Create schema for Git objects
CREATE OR REPLACE SCHEMA git_integration_db.git_objects;

USE DATABASE git_integration_db;
USE SCHEMA git_objects;
```

### Step 3: Create Secret for GitHub Authentication

```sql
-- Execute in both accounts (replace with your GitHub details)
CREATE OR REPLACE SECRET git_integration_db.git_objects.github_secret
  TYPE = password
  USERNAME = 'vhathor'  -- Replace with your GitHub username
  PASSWORD = 'your_personal_access_token_here';  -- Replace with your PAT from Step 1

-- Verify secret creation
SHOW SECRETS;
```

### Step 4: Create API Integration

```sql
-- Execute in both accounts
CREATE OR REPLACE API INTEGRATION github_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/vhathor')  -- Your GitHub account prefix
  ALLOWED_AUTHENTICATION_SECRETS = (git_integration_db.git_objects.github_secret)
  ENABLED = TRUE;

-- Verify API integration
SHOW API INTEGRATIONS;
```

### Step 5: Create Git Repository Stage

```sql
-- Execute in both accounts
CREATE OR REPLACE GIT REPOSITORY git_integration_db.git_objects.s3ot_repo
  API_INTEGRATION = github_api_integration
  GIT_CREDENTIALS = git_integration_db.git_objects.github_secret
  ORIGIN = 'https://github.com/vhathor/s3ot.git';

-- Verify repository creation
SHOW GIT REPOSITORIES;
```

### Step 6: Test Repository Access

```sql
-- Execute in both accounts to verify connection
ALTER GIT REPOSITORY git_integration_db.git_objects.s3ot_repo FETCH;

-- List files in the repository
LS @git_integration_db.git_objects.s3ot_repo/branches/main/;
```

## Part 3: Setting Up Workspaces for File Synchronization

### Step 7: Create Git-Integrated Workspace

**In both ACCOUNT_A and ACCOUNT_B:**

1. **Access Snowsight**:
   - Log into your Snowflake account via web interface
   - Navigate to "Projects" → "Workspaces"

2. **Create New Git Workspace**:
   - Click "Create Workspace" dropdown
   - Select "Create from Git repository"
   - **Repository**: Select `git_integration_db.git_objects.s3ot_repo`
   - **Branch**: `main`
   - **Authentication**: Select your `github_secret`
   - **Workspace name**: `S3OT_Shared_Workspace`
   - Click "Create"

### Step 8: Access and Edit the snow_github.sql File

1. **Navigate to the file**:
   - In your workspace, browse to `snow_github.sql`
   - The file should be visible and editable

2. **Set up author details**:
   - Go to "Changes" tab
   - Click ellipsis (⋯) → "Edit credentials"
   - Set your name and email for commits
   - Click "Update"

## Part 4: Workflow for Maintaining Synchronized Files

### Daily Workflow Example:

**Before making changes (in either account):**
```sql
-- Fetch latest changes from GitHub
ALTER GIT REPOSITORY git_integration_db.git_objects.s3ot_repo FETCH;
```

**In Workspace:**
1. **Pull latest changes**: Click "Pull" button in Changes tab
2. **Edit files**: Make changes to `snow_github.sql`
3. **Commit changes**: 
   - Go to Changes tab
   - Add commit message
   - Click "Commit"
4. **Push to GitHub**: Click "Push" to sync back to repository

### Example Commands for File Operations

**Execute SQL from the repository file:**
```sql
-- Execute the snow_github.sql file directly from Git stage
EXECUTE IMMEDIATE FROM @git_integration_db.git_objects.s3ot_repo/branches/main/snow_github.sql;
```

**Reference files in procedures:**
```sql
-- Create a procedure that uses the Git repository file
CREATE OR REPLACE PROCEDURE run_shared_sql()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  EXECUTE IMMEDIATE FROM @git_integration_db.git_objects.s3ot_repo/branches/main/snow_github.sql;
  RETURN 'Successfully executed shared SQL file';
END;
$$;
```

## Part 5: Best Practices for Multi-Account Synchronization

### Recommended Workflow:

1. **Designate a primary account** for major changes
2. **Use descriptive commit messages** to track changes between accounts
3. **Regular synchronization**: Pull before making changes, push after completing work
4. **Branch strategy**: Consider using separate branches for each account during development

### Monitoring and Maintenance:

```sql
-- Check repository status
SHOW GIT BRANCHES IN git_integration_db.git_objects.s3ot_repo;

-- View repository details
DESCRIBE GIT REPOSITORY git_integration_db.git_objects.s3ot_repo;

-- Refresh repository (fetch latest)
ALTER GIT REPOSITORY git_integration_db.git_objects.s3ot_repo FETCH;
```

## Troubleshooting Common Issues

1. **Authentication Errors**: Verify your personal access token has correct permissions
2. **File Access Issues**: Ensure the repository path is correct in file references
3. **Sync Conflicts**: Use the Workspace interface to resolve merge conflicts
4. **Permission Errors**: Verify ACCOUNTADMIN role is being used for setup

This setup ensures both Snowflake accounts maintain synchronized access to the same GitHub repository, with the ability to collaboratively edit and maintain the `snow_github.sql` file while keeping only one source of truth in GitHub.


