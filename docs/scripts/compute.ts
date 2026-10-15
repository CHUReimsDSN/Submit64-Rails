import {
  computeSidebar,
  computeVersion,
  computeIndexMd,
} from "vitepress-bigbang/scripts";

console.log("Compute started...");
computeSidebar();
computeVersion({ mode: 'ruby' });
computeIndexMd();
console.log("🎉 Compute done");
