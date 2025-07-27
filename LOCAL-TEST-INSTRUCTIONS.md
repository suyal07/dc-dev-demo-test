# Local Deployment Testing Instructions

## Steps to test the deployment locally:

1. **Start the local HTTP server** (in a new PowerShell window):
   ```powershell
   cd "C:\Users\Parth Suyal\Desktop\dc-deployments\dc-dev-demo-test"
   .\start-local-server.ps1
   ```
   Keep this window open during the entire test.

2. **Run the what-if deployment** (in your current window):
   ```powershell
   az deployment sub what-if --location uksouth --template-file ./templates/mainTemplate-local.json --parameters '@./parameters/dev/main.parameters.json'
   ```

3. **If what-if looks good, run the actual deployment**:
   ```powershell
   az deployment sub create --location uksouth --template-file ./templates/mainTemplate-local.json --parameters '@./parameters/dev/main.parameters.json' --name "dc-demo-dev-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
   ```

## What happens:
- The local HTTP server serves your local template files
- The main template uses http://localhost:8000/ URLs to access these templates
- This allows you to test with your local templates that have tags support

## After successful deployment:
1. Stop the HTTP server (Ctrl+C in the server window)
2. Push your templates to GitHub
3. Use the original mainTemplate.json (with GitHub URLs) for production deployments

## Files created for local testing:
- `mainTemplate-local.json` - Main template with localhost URLs
- `start-local-server.ps1` - Script to start the HTTP server
- `mainTemplate.json.backup` - Backup of your original main template
