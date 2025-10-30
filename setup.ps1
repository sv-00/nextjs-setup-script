# next-prisma-init.ps1
# -----------------------------------------------------------
# Automated setup for Next.js 16 + TypeScript + Prisma (MongoDB)
# with pnpm and build script handling (no approve-builds needed)
# -----------------------------------------------------------

Write-Host "🚀 Initializing Next.js project in current directory using pnpm..."
pnpm dlx create-next-app@latest . --typescript --src-dir --app --eslint --tailwind

# -----------------------------------------------------------
# Configure pnpm global settings
# -----------------------------------------------------------
Write-Host "🧩 Configuring pnpm global settings..."
pnpm config set reporter default
pnpm config set color true
pnpm config set loglevel info
pnpm config list

# -----------------------------------------------------------
# Configure pnpm build script permissions (before dependencies)
# -----------------------------------------------------------
Write-Host "🛠️ Adding pnpm.onlyBuiltDependencies for Prisma & Sharp..."
$pkgJson = "package.json"
if (Test-Path $pkgJson) {
    $json = Get-Content $pkgJson -Raw | ConvertFrom-Json
    if (-not $json.pnpm) { $json | Add-Member -MemberType NoteProperty -Name "pnpm" -Value @{} }
    $json.pnpm.onlyBuiltDependencies = @("@prisma/client", "prisma", "sharp")
    $json | ConvertTo-Json -Depth 5 | Set-Content -Path $pkgJson -Encoding UTF8
    Write-Host "✅ Updated pnpm.onlyBuiltDependencies in package.json"
}

# -----------------------------------------------------------
# Ensure src/lib folder exists for reusable utilities
# -----------------------------------------------------------
if (-not (Test-Path "src\lib")) { 
    Write-Host "📁 Creating lib folder..."
    New-Item -ItemType Directory -Path "src\lib" | Out-Null 
}

# -----------------------------------------------------------
# Create Prisma client singleton file (avoids hot reload issues)
# -----------------------------------------------------------
Write-Host "📝 Creating src/lib/prisma.ts..."
$prismaFile = "src\lib\prisma.ts"
$prismaCode = @'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
'@
Set-Content -Path $prismaFile -Value $prismaCode -Encoding UTF8

# -----------------------------------------------------------
# Install Prisma and environment dependencies
# -----------------------------------------------------------
Write-Host "📦 Installing Prisma, @prisma/client, and dotenv..."
pnpm add @prisma/client dotenv
pnpm add -D prisma

# -----------------------------------------------------------
# Initialize Prisma for MongoDB datasource
# -----------------------------------------------------------
Write-Host "📂 Running Prisma initialization (MongoDB)..."
pnpm exec prisma init --datasource-provider mongodb

# -----------------------------------------------------------
# Ensure dotenv import exists in prisma.config.ts (if generated)
# -----------------------------------------------------------
$prismaConfig = "prisma.config.ts"
if (Test-Path $prismaConfig) {
    Write-Host "🔧 Adding import 'dotenv/config' to prisma.config.ts (if missing)..."
    $config = Get-Content $prismaConfig
    if ($config -notmatch 'dotenv/config') {
        $fixed = @("import `"dotenv/config`";") + $config
        Set-Content -Path $prismaConfig -Value $fixed -Encoding UTF8
    }
}

# -----------------------------------------------------------
# Prepare .env with MongoDB connection string prompt
# -----------------------------------------------------------
Write-Host "`n🌍 Setting up environment variables..."
if (Test-Path ".env") { Clear-Content ".env" }
$databaseUrl = Read-Host "Enter your MongoDB connection string for DATABASE_URL"
Add-Content ".env" "DATABASE_URL=`"$databaseUrl`""

# -----------------------------------------------------------
# Add a hydration class in layout.tsx <html> tag
# -----------------------------------------------------------
$layout = "src\app\layout.tsx"
if (Test-Path $layout) {
    Write-Host "💄 Adding className='hydrated' to <html> in layout.tsx..."
    $html = Get-Content $layout -Raw
    $htmlUpdated = $html -replace '<html lang="en">', '<html lang="en" className="hydrated">'
    Set-Content -Path $layout -Value $htmlUpdated -Encoding UTF8
}

# -----------------------------------------------------------
# Generate Prisma client
# -----------------------------------------------------------
Write-Host "⚙️ Generating Prisma Client..."
pnpm exec prisma generate

Write-Host "`n✅ Setup complete! You can now run:"
Write-Host "👉 pnpm dev"
