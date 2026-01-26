import fs from "fs";
import path from "path";

export function computeVersion() {
  const packageJsonPath = '../lib/submit64/version.rb'
  const fileAbsPath = path.resolve(process.cwd(), packageJsonPath);
  const content = fs.readFileSync(fileAbsPath, "utf-8");
  const match = content.match(/VERSION\s*=\s*["'](\d+\.\d+\.\d+)["']/)
  const fileToWritePath = ".vitepress/generated/version.ts";
  const fileContent = `export const version = '${match?.[1] ?? '???'}'`;
  
  fs.writeFileSync(fileToWritePath, fileContent);
  console.log("✅ Version computed");
}
