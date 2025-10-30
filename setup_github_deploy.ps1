# Setup GitHub deployment for MediaGenie

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "https://github.com/your-username/mediagenie-demo.git",
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "mediagenie-demo-gzdvb5cbeceybwh4"
)

Write-Host "=== Setting up GitHub Deployment for MediaGenie ===" -ForegroundColor Green
Write-Host ""

# Check if git is initialized
if (!(Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit for Azure deployment"
}

# Add GitHub remote if not exists
$remotes = git remote
if ($remotes -notcontains "origin") {
    Write-Host "Adding GitHub remote..." -ForegroundColor Yellow
    git remote add origin $GitHubRepo
    Write-Host "Please update the GitHubRepo parameter with your actual repository URL" -ForegroundColor Red
    Write-Host "Example: .\setup_github_deploy.ps1 -GitHubRepo 'https://github.com/yourusername/mediagenie-demo.git'" -ForegroundColor Yellow
} else {
    Write-Host "GitHub remote already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Create a GitHub repository at: https://github.com/new" -ForegroundColor White
Write-Host "2. Push your code to GitHub:" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. In Azure Portal, go to your App Service '$AppServiceName'" -ForegroundColor White
Write-Host "4. Go to 'Deployment Center' -> 'GitHub'" -ForegroundColor White
Write-Host "5. Connect your GitHub account and select the repository" -ForegroundColor White
Write-Host "6. Configure environment variables in App Service settings" -ForegroundColor White
Write-Host ""
Write-Host "7. Push changes to trigger automatic deployment:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Cyan
Write-Host "   git commit -m 'Deploy to Azure'" -ForegroundColor Cyan
Write-Host "   git push origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 GitHub deployment setup complete!" -ForegroundColor Green
Write-Host "Check GITHUB_DEPLOYMENT.md for detailed instructions" -ForegroundColor Yellow