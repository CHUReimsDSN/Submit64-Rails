import fs from "fs";
import path from "path";

type TSidebarEntry = {
  text: string;
  link?: string;
  items: TSidebarEntry[];
  collapsed?: boolean;
};
type TSidebarFolder = {
  path: string;
  label: string;
  children?: TSidebarFolder[];
};

export function computeSidebar() {
  const sidebarsData: Record<string, TSidebarEntry[]> = {};
  const fileToWritePath = ".vitepress/generated/sidebar.ts";
  const foldersSidebar: TSidebarFolder[] = [
    {
      path: "./documentation",
      label: "Documentation",
      children: [
        {
          path: "./documentation/exemples",
          label: "Exemples",
        },
      ],
    },
  ];

  const getSidebarEntry = (
    folder: TSidebarFolder,
    collapsed = false,
  ): TSidebarEntry => {
    const folderAbsPath = path.resolve(process.cwd(), folder.path);
    const entry: TSidebarEntry = { text: folder.label, items: [] };

    if (!fs.existsSync(folderAbsPath)) {
      console.warn(`⚠️ Dossier non trouvé: ${folderAbsPath}`);
      return entry;
    }

    const files = fs
      .readdirSync(folderAbsPath)
      .filter((f) => f.endsWith(".md"))
      .sort();

    files.forEach((file) => {
      const filePath = path.join(folderAbsPath, file);
      const content = fs.readFileSync(filePath, "utf-8");
      const title =
        content.match(/^\s*title:\s*(.+)$/m)?.[1]?.trim() ??
        file.replace(".md", "");

      const link =
        "/" +
        path.posix.join(
          path.relative(process.cwd(), filePath).replace(/\\/g, "/"),
        );

      const item: TSidebarEntry = { text: title, link, items: [] };
      if (collapsed) {
        item.collapsed = true;
      }
      entry.items.push(item);
    });

    folder.children?.forEach((child) => {
      const childEntry = getSidebarEntry(child);
      entry.items.push(childEntry);
    });

    if ((entry.items?.length ?? 0) > 0) {
      entry.collapsed = true
    }

    return entry;
  };

  foldersSidebar.forEach(folder => {
    const folderKey = `/${folder.path.replace(/^\.\/|\/$/g, "")}/`;
    sidebarsData[folderKey] = [getSidebarEntry(folder)];
  });

  const sidebarString = `export const sidebar = ${JSON.stringify(sidebarsData, null, 2)};`;
  fs.mkdirSync(path.dirname(fileToWritePath), { recursive: true });
  fs.writeFileSync(fileToWritePath, sidebarString);

  console.log("✅ Sidebar computed");
}
