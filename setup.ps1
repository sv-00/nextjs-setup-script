Write-Host "🚀 Initializing Next.js project in current directory using pnpm..."
pnpm dlx create-next-app@latest . --typescript --src-dir --app --eslint --tailwind

# Ensure lib folder exists
if (-not (Test-Path "src\lib")) { New-Item -ItemType Directory -Path "src\lib" | Out-Null }

# Create Prisma client singleton file
Write-Host "📝 Creating src\lib\prisma.ts..."
$prismaFile = "src\lib\prisma.ts"
$prismaCode = @'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
'@
Set-Content -Path $prismaFile -Value $prismaCode -Encoding UTF8

# Install Prisma + dotenv with pnpm
Write-Host "📦 Installing Prisma, @prisma/client, and dotenv..."
pnpm add @prisma/client dotenv
pnpm add -D prisma

# Initialize Prisma
Write-Host "📂 Running Prisma initialization (MongoDB)..."
pnpm exec prisma init --datasource-provider mongodb

# Ensure dotenv import exists in prisma.config.ts
$prismaConfig = "prisma.config.ts"
if (Test-Path $prismaConfig) {
    Write-Host "🔧 Adding import 'dotenv/config' to prisma.config.ts (if missing)..."
    $config = Get-Content $prismaConfig
    if ($config -notmatch 'dotenv/config') {
        $fixed = @("import `"dotenv/config`";") + $config
        Set-Content -Path $prismaConfig -Value $fixed -Encoding UTF8
    }
}

# Clear .env and add MongoDB prompt
Write-Host "`n🌍 Setting up environment variables..."
if (Test-Path ".env") { Clear-Content ".env" }
$databaseUrl = Read-Host "Enter your MongoDB connection string for DATABASE_URL"
Add-Content ".env" "DATABASE_URL=`"$databaseUrl`""

# Modify <html> tag in layout.tsx for hydration
$layout = "src\app\layout.tsx"
if (Test-Path $layout) {
    Write-Host "💄 Adding className='hydrated' to <html> in layout.tsx..."
    $html = Get-Content $layout -Raw
    $htmlUpdated = $html -replace '<html lang="en">', '<html lang="en" className="hydrated">'
    Set-Content -Path $layout -Value $htmlUpdated -Encoding UTF8
}

# Generate Prisma client
Write-Host "⚙️ Generating Prisma Client..."
pnpm exec prisma generate

Write-Host "`n✅ Setup complete! You can now run:"
Write-Host "👉 pnpm dev"
