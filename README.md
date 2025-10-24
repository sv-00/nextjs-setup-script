# nextjs-setup-script
PowerShell script to set up a Next.js + Prisma + MongoDB app using pnpm

## 🧩 Features

- Creates a Next.js 15 app using PNPM
- Adds Prisma + MongoDB + dotenv setup
- Prompts for your `DATABASE_URL`
- Injects global client (`src/lib/prisma.ts`)
- Edits layout to use `className="hydrated"`

## ⚡ Usage

Run this command from PowerShell in your project directory created:

```irm https://raw.githubusercontent.com/sv-00/nextjs-setup-script/main/setup-nextjs.ps1 | iex```


## 🪄 Troubleshoot

If You See an Error About Script Execution Policy, run this command and then run the script again:

```Set-ExecutionPolicy RemoteSigned -Scope CurrentUser```
