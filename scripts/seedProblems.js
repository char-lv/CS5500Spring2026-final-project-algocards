const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const args = process.argv.slice(2);
const listFilter = args.includes("--list")
  ? args[args.indexOf("--list") + 1]
  : null;
const forceOverwrite = args.includes("--force");

const problems = [
  // ── Array ──────────────────────────────────────────────────
  { id: "1",   title: "Two Sum",                                titleSlug: "two-sum",                                       difficulty: "Easy",   acRate: 53.5, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },
  { id: "4",   title: "Median of Two Sorted Arrays",            titleSlug: "median-of-two-sorted-arrays",                   difficulty: "Hard",   acRate: 40.9, isPaidOnly: false, hasSolution: true,  listTags: ["array", "hot100"] },
  { id: "11",  title: "Container With Most Water",              titleSlug: "container-with-most-water",                     difficulty: "Medium", acRate: 54.5, isPaidOnly: false, hasSolution: true,  listTags: ["array", "two-pointers", "blind75", "hot100"] },
  { id: "15",  title: "3Sum",                                   titleSlug: "3sum",                                          difficulty: "Medium", acRate: 34.7, isPaidOnly: false, hasSolution: true,  listTags: ["array", "two-pointers", "blind75", "hot100"] },
  { id: "26",  title: "Remove Duplicates from Sorted Array",    titleSlug: "remove-duplicates-from-sorted-array",           difficulty: "Easy",   acRate: 56.8, isPaidOnly: false, hasSolution: true,  listTags: ["array", "hot100"] },
  { id: "33",  title: "Search in Rotated Sorted Array",         titleSlug: "search-in-rotated-sorted-array",                difficulty: "Medium", acRate: 40.2, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },
  { id: "53",  title: "Maximum Subarray",                       titleSlug: "maximum-subarray",                              difficulty: "Medium", acRate: 50.9, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },
  { id: "56",  title: "Merge Intervals",                        titleSlug: "merge-intervals",                               difficulty: "Medium", acRate: 47.0, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },
  { id: "121", title: "Best Time to Buy and Sell Stock",        titleSlug: "best-time-to-buy-and-sell-stock",               difficulty: "Easy",   acRate: 54.2, isPaidOnly: false, hasSolution: true,  listTags: ["array", "sliding-window", "blind75", "hot100"] },
  { id: "152", title: "Maximum Product Subarray",               titleSlug: "maximum-product-subarray",                      difficulty: "Medium", acRate: 34.9, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },
  { id: "153", title: "Find Minimum in Rotated Sorted Array",   titleSlug: "find-minimum-in-rotated-sorted-array",          difficulty: "Medium", acRate: 49.3, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75"] },
  { id: "217", title: "Contains Duplicate",                     titleSlug: "contains-duplicate",                            difficulty: "Easy",   acRate: 61.8, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75"] },
  { id: "238", title: "Product of Array Except Self",           titleSlug: "product-of-array-except-self",                  difficulty: "Medium", acRate: 65.2, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },
  { id: "268", title: "Missing Number",                         titleSlug: "missing-number",                                difficulty: "Easy",   acRate: 64.0, isPaidOnly: false, hasSolution: true,  listTags: ["array"] },
  { id: "347", title: "Top K Frequent Elements",                titleSlug: "top-k-frequent-elements",                       difficulty: "Medium", acRate: 61.8, isPaidOnly: false, hasSolution: true,  listTags: ["array", "blind75", "hot100"] },

  // ── String ─────────────────────────────────────────────────
  { id: "3",   title: "Longest Substring Without Repeating Characters", titleSlug: "longest-substring-without-repeating-characters", difficulty: "Medium", acRate: 34.5, isPaidOnly: false, hasSolution: true, listTags: ["string", "sliding-window", "blind75", "hot100"] },
  { id: "5",   title: "Longest Palindromic Substring",          titleSlug: "longest-palindromic-substring",                 difficulty: "Medium", acRate: 33.5, isPaidOnly: false, hasSolution: true,  listTags: ["string", "blind75", "hot100"] },
  { id: "20",  title: "Valid Parentheses",                      titleSlug: "valid-parentheses",                             difficulty: "Easy",   acRate: 40.7, isPaidOnly: false, hasSolution: true,  listTags: ["string", "stack", "blind75", "hot100"] },
  { id: "49",  title: "Group Anagrams",                         titleSlug: "group-anagrams",                                difficulty: "Medium", acRate: 67.6, isPaidOnly: false, hasSolution: true,  listTags: ["string", "blind75", "hot100"] },
  { id: "125", title: "Valid Palindrome",                       titleSlug: "valid-palindrome",                              difficulty: "Easy",   acRate: 46.3, isPaidOnly: false, hasSolution: true,  listTags: ["string", "two-pointers", "blind75"] },
  { id: "242", title: "Valid Anagram",                          titleSlug: "valid-anagram",                                 difficulty: "Easy",   acRate: 63.7, isPaidOnly: false, hasSolution: true,  listTags: ["string", "blind75"] },
  { id: "424", title: "Longest Repeating Character Replacement",titleSlug: "longest-repeating-character-replacement",       difficulty: "Medium", acRate: 51.9, isPaidOnly: false, hasSolution: true,  listTags: ["string", "sliding-window", "blind75"] },
  { id: "647", title: "Palindromic Substrings",                 titleSlug: "palindromic-substrings",                        difficulty: "Medium", acRate: 68.5, isPaidOnly: false, hasSolution: true,  listTags: ["string", "blind75"] },
  { id: "76",  title: "Minimum Window Substring",               titleSlug: "minimum-window-substring",                      difficulty: "Hard",   acRate: 42.0, isPaidOnly: false, hasSolution: true,  listTags: ["string", "sliding-window", "blind75", "hot100"] },

  // ── Two Pointers ───────────────────────────────────────────
  { id: "42",  title: "Trapping Rain Water",                    titleSlug: "trapping-rain-water",                           difficulty: "Hard",   acRate: 61.3, isPaidOnly: false, hasSolution: true,  listTags: ["two-pointers", "hot100"] },
  { id: "167", title: "Two Sum II",                             titleSlug: "two-sum-ii-input-array-is-sorted",              difficulty: "Medium", acRate: 60.9, isPaidOnly: false, hasSolution: true,  listTags: ["two-pointers"] },

  // ── Sliding Window ─────────────────────────────────────────
  { id: "239", title: "Sliding Window Maximum",                 titleSlug: "sliding-window-maximum",                        difficulty: "Hard",   acRate: 46.5, isPaidOnly: false, hasSolution: true,  listTags: ["sliding-window", "queue", "hot100"] },
  { id: "567", title: "Permutation in String",                  titleSlug: "permutation-in-string",                         difficulty: "Medium", acRate: 44.9, isPaidOnly: false, hasSolution: true,  listTags: ["sliding-window"] },

  // ── Tree ───────────────────────────────────────────────────
  { id: "94",  title: "Binary Tree Inorder Traversal",          titleSlug: "binary-tree-inorder-traversal",                 difficulty: "Easy",   acRate: 74.4, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "hot100"] },
  { id: "100", title: "Same Tree",                              titleSlug: "same-tree",                                     difficulty: "Easy",   acRate: 59.6, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75"] },
  { id: "102", title: "Binary Tree Level Order Traversal",      titleSlug: "binary-tree-level-order-traversal",             difficulty: "Medium", acRate: 67.5, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "queue", "blind75", "hot100"] },
  { id: "104", title: "Maximum Depth of Binary Tree",           titleSlug: "maximum-depth-of-binary-tree",                  difficulty: "Easy",   acRate: 74.7, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75", "hot100"] },
  { id: "124", title: "Binary Tree Maximum Path Sum",           titleSlug: "binary-tree-maximum-path-sum",                  difficulty: "Hard",   acRate: 39.9, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75", "hot100"] },
  { id: "226", title: "Invert Binary Tree",                     titleSlug: "invert-binary-tree",                            difficulty: "Easy",   acRate: 77.4, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75", "hot100"] },
  { id: "230", title: "Kth Smallest Element in a BST",         titleSlug: "kth-smallest-element-in-a-bst",                 difficulty: "Medium", acRate: 71.8, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75"] },
  { id: "235", title: "Lowest Common Ancestor of BST",         titleSlug: "lowest-common-ancestor-of-a-binary-search-tree",difficulty: "Medium", acRate: 64.6, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75"] },
  { id: "572", title: "Subtree of Another Tree",               titleSlug: "subtree-of-another-tree",                       difficulty: "Easy",   acRate: 46.2, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75"] },
  { id: "105", title: "Construct Binary Tree from Preorder and Inorder", titleSlug: "construct-binary-tree-from-preorder-and-inorder-traversal", difficulty: "Medium", acRate: 64.4, isPaidOnly: false, hasSolution: true, listTags: ["tree", "blind75", "hot100"] },
  { id: "297", title: "Serialize and Deserialize Binary Tree", titleSlug: "serialize-and-deserialize-binary-tree",          difficulty: "Hard",   acRate: 56.5, isPaidOnly: false, hasSolution: true,  listTags: ["tree", "blind75"] },

  // ── Graph ──────────────────────────────────────────────────
  { id: "133", title: "Clone Graph",                            titleSlug: "clone-graph",                                   difficulty: "Medium", acRate: 56.8, isPaidOnly: false, hasSolution: true,  listTags: ["graph", "blind75"] },
  { id: "200", title: "Number of Islands",                      titleSlug: "number-of-islands",                             difficulty: "Medium", acRate: 58.5, isPaidOnly: false, hasSolution: true,  listTags: ["graph", "blind75", "hot100"] },
  { id: "207", title: "Course Schedule",                        titleSlug: "course-schedule",                               difficulty: "Medium", acRate: 46.2, isPaidOnly: false, hasSolution: true,  listTags: ["graph", "blind75", "hot100"] },
  { id: "417", title: "Pacific Atlantic Water Flow",            titleSlug: "pacific-atlantic-water-flow",                   difficulty: "Medium", acRate: 53.9, isPaidOnly: false, hasSolution: true,  listTags: ["graph", "blind75"] },
  { id: "128", title: "Longest Consecutive Sequence",           titleSlug: "longest-consecutive-sequence",                  difficulty: "Medium", acRate: 47.0, isPaidOnly: false, hasSolution: true,  listTags: ["graph", "array", "blind75", "hot100"] },

  // ── Stack ──────────────────────────────────────────────────
  { id: "84",  title: "Largest Rectangle in Histogram",        titleSlug: "largest-rectangle-in-histogram",                difficulty: "Hard",   acRate: 44.5, isPaidOnly: false, hasSolution: true,  listTags: ["stack", "hot100"] },
  { id: "150", title: "Evaluate Reverse Polish Notation",       titleSlug: "evaluate-reverse-polish-notation",              difficulty: "Medium", acRate: 49.0, isPaidOnly: false, hasSolution: true,  listTags: ["stack"] },
  { id: "155", title: "Min Stack",                              titleSlug: "min-stack",                                     difficulty: "Medium", acRate: 53.5, isPaidOnly: false, hasSolution: true,  listTags: ["stack", "blind75", "hot100"] },
  { id: "739", title: "Daily Temperatures",                     titleSlug: "daily-temperatures",                            difficulty: "Medium", acRate: 66.9, isPaidOnly: false, hasSolution: true,  listTags: ["stack", "hot100"] },

  // ── Queue ──────────────────────────────────────────────────
  { id: "225", title: "Implement Stack using Queues",           titleSlug: "implement-stack-using-queues",                  difficulty: "Easy",   acRate: 64.2, isPaidOnly: false, hasSolution: true,  listTags: ["queue"] },
  { id: "232", title: "Implement Queue using Stacks",           titleSlug: "implement-queue-using-stacks",                  difficulty: "Easy",   acRate: 65.3, isPaidOnly: false, hasSolution: true,  listTags: ["queue"] },
];

const command = args[0]; // seed | delete | list | stats

async function main() {
  switch (command) {
    case "delete":  await deleteProblem(); break;
    case "remove":  await removeFromList(); break;
    case "list":    await listProblems(); break;
    case "stats":   await showStats(); break;
    default:        await seed(); break;
  }
}

async function seed() {
  const toSeed = listFilter
    ? problems.filter((p) => p.listTags.includes(listFilter))
    : problems;

  console.log(`🚀 Seeding ${toSeed.length} problems${listFilter ? ` for [${listFilter}]` : ""}...\n`);

  const batch = db.batch();
  for (const p of toSeed) {
    const ref = db.collection("problems").doc(p.titleSlug);
    batch.set(ref, {
      questionFrontendId: p.id,
      title: p.title,
      titleSlug: p.titleSlug,
      difficulty: p.difficulty,
      acRate: p.acRate,
      isPaidOnly: p.isPaidOnly,
      hasSolution: p.hasSolution,
      listTags: p.listTags,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: !forceOverwrite });
  }

  await batch.commit();
  console.log(`✅ Seeded ${toSeed.length} problems.`);
  await showStats();
}


async function deleteProblem() {
  const slugIndex = args.indexOf("--slug");
  if (slugIndex === -1) {
    console.error("❌ Usage: node seedProblems.js delete --slug <titleSlug>");
    process.exit(1);
  }
  const slug = args[slugIndex + 1];
  await db.collection("problems").doc(slug).delete();
  console.log(`🗑️  Deleted: ${slug}`);
  process.exit(0);
}

async function removeFromList() {
  const slugIndex = args.indexOf("--slug");
  const listIndex = args.indexOf("--list");
  if (slugIndex === -1 || listIndex === -1) {
    console.error("❌ Usage: node seedProblems.js remove --slug <titleSlug> --list <listTag>");
    process.exit(1);
  }
  const slug = args[slugIndex + 1];
  const list = args[listIndex + 1];

  await db.collection("problems").doc(slug).update({
    listTags: admin.firestore.FieldValue.arrayRemove(list),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Removed [${list}] tag from: ${slug}`);
  process.exit(0);
}

async function listProblems() {
  const list = listFilter || "array";
  const snapshot = await db.collection("problems")
    .whereField ? 
    db.collection("problems").where("listTags", "array-contains", list).get() :
    db.collection("problems").where("listTags", "array-contains", list).get();

  const snap = await db.collection("problems")
    .where("listTags", "array-contains", list)
    .orderBy("questionFrontendId")
    .get();

  console.log(`\n📋 [${list}] — ${snap.size} problems:\n`);
  snap.forEach((doc) => {
    const d = doc.data();
    console.log(`  #${d.questionFrontendId.padEnd(4)} ${d.difficulty.padEnd(7)} ${d.title}`);
  });
  process.exit(0);
}

async function showStats() {
  const snap = await db.collection("problems").get();
  const counts = {};

  snap.forEach((doc) => {
    const tags = doc.data().listTags || [];
    tags.forEach((tag) => {
      counts[tag] = (counts[tag] || 0) + 1;
    });
  });

  console.log(`\n📊 Firestore stats (${snap.size} total problems):`);
  Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .forEach(([tag, count]) => {
      const bar = "█".repeat(Math.floor(count / 2));
      console.log(`   ${tag.padEnd(16)} ${String(count).padStart(3)}  ${bar}`);
    });
  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});