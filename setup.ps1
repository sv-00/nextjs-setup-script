# next-prisma-init.ps1
# -----------------------------------------------------------
# Automated setup for Next.js 16 + TypeScript + Prisma (MongoDB)
# with package manager selection
# -----------------------------------------------------------

Write-Host "🚀 Next.js + Prisma (MongoDB) Setup"
Write-Host "=============================================="

# -----------------------------------------------------------
# Package manager selection
# -----------------------------------------------------------
Write-Host "`n📦 Select Package Manager:"
Write-Host "1) pnpm (recommended)"
Write-Host "2) npm"
$choice = Read-Host "Enter choice (1 or 2)"

if ($choice -eq "2") {
    $pkg = "npm"
    Write-Host "Using npm..."
} else {
    $pkg = "pnpm" 
    Write-Host "Using pnpm..."
}

# -----------------------------------------------------------
# Linter selection
# -----------------------------------------------------------
Write-Host "`n🔍 Select Linter:"
Write-Host "1) ESLint (recommended)"
Write-Host "2) Biome"
Write-Host "3) None"
$linterChoice = Read-Host "Enter choice (1-3)"

$linterFlag = ""
switch ($linterChoice) {
    "2" { $linterFlag = "--biome" }
    "3" { $linterFlag = "--no-eslint" }
    default { $linterFlag = "--eslint" }
}

# -----------------------------------------------------------
# Create Next.js project FIRST
# -----------------------------------------------------------
Write-Host "`n🔄 Creating Next.js project..."
if ($pkg -eq "npm") {
    npx create-next-app@latest . --typescript --tailwind --src-dir --app --no-import-alias $linterFlag --yes
} else {
    pnpm dlx create-next-app@latest . --typescript --tailwind --src-dir --app --no-import-alias $linterFlag
    
    # Keep your original pnpm config
    Write-Host "🧩 Configuring pnpm..."
    pnpm config set reporter default
    pnpm config set color true
    pnpm config set loglevel info
    
    Write-Host "🛠️ Adding pnpm.onlyBuiltDependencies..."
    $pkgJson = "package.json"
    if (Test-Path $pkgJson) {
        $json = Get-Content $pkgJson -Raw | ConvertFrom-Json
        if (-not $json.pnpm) { $json | Add-Member -MemberType NoteProperty -Name "pnpm" -Value @{} }
        $json.pnpm.onlyBuiltDependencies = @("@prisma/client", "prisma", "sharp")
        $json | ConvertTo-Json -Depth 5 | Set-Content -Path $pkgJson -Encoding UTF8
    }
}

# -----------------------------------------------------------
# Setup environment AFTER project creation
# -----------------------------------------------------------
Write-Host "`n🌍 Setting up environment variables..."
if (Test-Path ".env") { Clear-Content ".env" }
$databaseUrl = Read-Host "Enter your MongoDB connection string for DATABASE_URL"
Add-Content ".env" "DATABASE_URL=`"$databaseUrl`""

# -----------------------------------------------------------
# Create lib folder and Prisma client
# -----------------------------------------------------------
if (-not (Test-Path "src\lib")) { 
    New-Item -ItemType Directory -Path "src\lib" | Out-Null 
}

Write-Host "📝 Creating Prisma client..."
$prismaCode = @'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
'@
Set-Content -Path "src\lib\prisma.ts" -Value $prismaCode -Encoding UTF8

# -----------------------------------------------------------
# Install dependencies
# -----------------------------------------------------------
Write-Host "`n📦 Installing dependencies..."
if ($pkg -eq "pnpm") {
    pnpm add @prisma/client dotenv
    pnpm add -D prisma
} else {
    npm install @prisma/client dotenv
    npm install -D prisma
}

# -----------------------------------------------------------
# Initialize Prisma
# -----------------------------------------------------------
Write-Host "`n📂 Initializing Prisma with MongoDB..."
if ($pkg -eq "pnpm") {
    pnpm exec prisma init --datasource-provider mongodb
} else {
    npx prisma init --datasource-provider mongodb
}

# -----------------------------------------------------------
# Update Prisma schema with environment variable
# -----------------------------------------------------------
Write-Host "`n🔧 Updating Prisma schema to use env variable..."
$schemaPath = "prisma\schema.prisma"
if (Test-Path $schemaPath) {
    $schemaContent = Get-Content $schemaPath -Raw
    # Replace the example URL with env variable
    $updatedSchema = $schemaContent -replace 'env\("DATABASE_URL"\)', 'env("DATABASE_URL")'
    Set-Content -Path $schemaPath -Value $updatedSchema -Encoding UTF8
}

# -----------------------------------------------------------
# Update layout
# -----------------------------------------------------------
$layout = "src\app\layout.tsx"
if (Test-Path $layout) {
    Write-Host "`n💄 Updating layout..."
    $html = Get-Content $layout -Raw
    $htmlUpdated = $html -replace '<html lang="en">', '<html lang="en" className="hydrated">'
    Set-Content -Path $layout -Value $htmlUpdated -Encoding UTF8
}

# -----------------------------------------------------------
# Generate Prisma client (NOW with env vars available)
# -----------------------------------------------------------
Write-Host "`n⚙️ Generating Prisma Client..."
if ($pkg -eq "pnpm") {
    pnpm exec prisma generate
} else {
    npx prisma generate
}

Write-Host "`n✅ Setup complete!"
if ($pkg -eq "pnpm") {
    Write-Host "👉 Run: pnpm dev"
} else {
    Write-Host "👉 Run: npm run dev"
}
