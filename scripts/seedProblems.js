const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const curatedProblemSets = require("./curatedProblemSets");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const args = process.argv.slice(2);
const command = args[0];
const listFilter = getFlagValue("--list");
const forceOverwrite = args.includes("--force");
const dryRun = args.includes("--dry-run");

const LEETCODE_GRAPHQL_URL = "https://leetcode.com/graphql";
const LEETCODE_PAGE_SIZE = getPositiveIntFlag("--page-size") || 200;
const LEETCODE_FETCH_LIMIT = getPositiveIntFlag("--limit");
const WRITE_BATCH_SIZE = 450;
const QUESTION_LIST_QUERY = `
  query problemsetQuestionList(
    $categorySlug: String
    $skip: Int
    $limit: Int
    $filters: QuestionListFilterInput
  ) {
    problemsetQuestionList: questionList(
      categorySlug: $categorySlug
      skip: $skip
      limit: $limit
      filters: $filters
    ) {
      total: totalNum
      questions: data {
        questionFrontendId
        title
        titleSlug
        difficulty
        acRate
        isPaidOnly
        hasSolution
        hasVideoSolution
        topicTags {
          name
          slug
        }
      }
    }
  }
`;

const manualProblems = [
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

async function main() {
  switch (command) {
    case "delete":  await deleteProblem(); break;
    case "remove":  await removeFromList(); break;
    case "list":    await listProblems(); break;
    case "metadata": await refreshMetadata(); break;
    case "stats":   await showStats(); break;
    default:        await seed(); break;
  }
}

async function seed() {
  const problems = await buildProblemCatalog();
  const toSeed = listFilter
    ? problems.filter((p) => p.listTags.includes(listFilter))
    : problems;

  console.log(`🚀 Seeding ${toSeed.length} problems${listFilter ? ` for [${listFilter}]` : ""}...\n`);

  if (dryRun) {
    console.log("🧪 Dry run enabled. No Firestore writes were performed.");
    console.log("Preview:");
    toSeed.slice(0, 10).forEach((problem) => {
      console.log(
        `  #${problem.id.padEnd(4)} ${problem.difficulty.padEnd(7)} ${problem.title} [${problem.listTags.join(", ")}]`
      );
    });
    process.exit(0);
  }

  for (const batchItems of chunkArray(toSeed, WRITE_BATCH_SIZE)) {
    const batch = db.batch();
    for (const p of batchItems) {
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
    console.log(`✅ Wrote batch of ${batchItems.length} problems.`);
  }

  if (!listFilter) {
    await writeProblemCatalogMetadata(problems);
  } else {
    console.log("ℹ️ Skipped metadata refresh because --list performed a partial seed.");
  }

  console.log(`✅ Seeded ${toSeed.length} problems.`);
  await showStats();
}

async function buildProblemCatalog() {
  console.log("🌐 Fetching problem catalog from LeetCode...");
  const fetchedProblems = await fetchProblemCatalogFromLeetCode();
  const mergedProblems = mergeProblems({
    liveProblems: fetchedProblems,
    manualProblems,
  });
  const taggedProblems = applyCuratedListTags(mergedProblems);

  console.log(
    `🧩 Catalog ready: ${taggedProblems.length} total problems ` +
    `(${fetchedProblems.length} live + ${manualProblems.length} manual curated entries).`
  );

  logCuratedCoverage(taggedProblems);

  return taggedProblems;
}

async function fetchProblemCatalogFromLeetCode() {
  const problems = [];
  let total = null;
  let skip = 0;

  while (total === null || skip < total) {
    if (LEETCODE_FETCH_LIMIT && problems.length >= LEETCODE_FETCH_LIMIT) {
      break;
    }

    const currentLimit = LEETCODE_FETCH_LIMIT
      ? Math.min(LEETCODE_PAGE_SIZE, LEETCODE_FETCH_LIMIT - problems.length)
      : LEETCODE_PAGE_SIZE;

    const response = await fetch(LEETCODE_GRAPHQL_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        operationName: "problemsetQuestionList",
        variables: {
          categorySlug: "",
          skip,
          limit: currentLimit,
          filters: {},
        },
        query: QUESTION_LIST_QUERY,
      }),
    });

    if (!response.ok) {
      throw new Error(`LeetCode GraphQL request failed with HTTP ${response.status}`);
    }

    const payload = await response.json();
    if (payload.errors?.length) {
      throw new Error(payload.errors.map((error) => error.message).join("; "));
    }

    const result = payload?.data?.problemsetQuestionList;
    if (!result || !Array.isArray(result.questions)) {
      throw new Error("Invalid LeetCode GraphQL response.");
    }

    total = result.total;
    const normalizedProblems = result.questions
      .map(normalizeLeetCodeProblem)
      .filter(Boolean);

    problems.push(...normalizedProblems);
    skip += result.questions.length;

    console.log(`  • fetched ${problems.length}/${LEETCODE_FETCH_LIMIT || total}`);

    if (result.questions.length === 0) {
      break;
    }
  }

  return problems;
}

function normalizeLeetCodeProblem(problem) {
  if (!problem?.questionFrontendId || !problem?.titleSlug || !problem?.title) {
    return null;
  }

  return {
    id: String(problem.questionFrontendId),
    title: problem.title,
    titleSlug: problem.titleSlug,
    difficulty: problem.difficulty || "Medium",
    acRate: normalizeAcRate(problem.acRate),
    isPaidOnly: Boolean(problem.isPaidOnly),
    hasSolution: Boolean(problem.hasSolution || problem.hasVideoSolution),
    listTags: uniqueTags((problem.topicTags || []).map((tag) => normalizeTag(tag.slug))),
  };
}

function mergeProblems({ liveProblems, manualProblems }) {
  const mergedBySlug = new Map();

  for (const problem of liveProblems) {
    mergedBySlug.set(problem.titleSlug, {
      ...problem,
      listTags: uniqueTags(problem.listTags),
    });
  }

  for (const manualProblem of manualProblems) {
    const existingProblem = mergedBySlug.get(manualProblem.titleSlug);
    if (!existingProblem) {
      mergedBySlug.set(manualProblem.titleSlug, {
        ...manualProblem,
        acRate: normalizeAcRate(manualProblem.acRate),
        listTags: uniqueTags(manualProblem.listTags),
      });
      continue;
    }

    mergedBySlug.set(manualProblem.titleSlug, {
      ...existingProblem,
      id: existingProblem.id || manualProblem.id,
      title: existingProblem.title || manualProblem.title,
      titleSlug: existingProblem.titleSlug || manualProblem.titleSlug,
      difficulty: existingProblem.difficulty || manualProblem.difficulty,
      acRate: normalizeAcRate(existingProblem.acRate ?? manualProblem.acRate),
      isPaidOnly: existingProblem.isPaidOnly ?? manualProblem.isPaidOnly,
      hasSolution: existingProblem.hasSolution ?? manualProblem.hasSolution,
      listTags: uniqueTags([
        ...(manualProblem.listTags || []),
        ...(existingProblem.listTags || []),
      ]),
    });
  }

  return Array.from(mergedBySlug.values()).sort(compareProblemsById);
}

function applyCuratedListTags(problems) {
  const curatedTagNames = new Set(Object.keys(curatedProblemSets));
  const idToTags = new Map();

  for (const [tag, problemIds] of Object.entries(curatedProblemSets)) {
    for (const problemId of problemIds) {
      const normalizedProblemId = String(problemId || "").trim();
      if (!normalizedProblemId) {
        continue;
      }

      if (!idToTags.has(normalizedProblemId)) {
        idToTags.set(normalizedProblemId, new Set());
      }
      idToTags.get(normalizedProblemId).add(tag);
    }
  }

  return problems.map((problem) => {
    const curatedTags = Array.from(idToTags.get(problem.id) || []);
    const baseListTags = (problem.listTags || []).filter(
      (tag) => !curatedTagNames.has(tag)
    );

    return {
      ...problem,
      listTags: uniqueTags([
        ...baseListTags,
        ...curatedTags,
      ]),
    };
  });
}

function logCuratedCoverage(problems) {
  const counts = Object.keys(curatedProblemSets)
    .sort()
    .map((tag) => {
      const count = problems.filter((problem) => problem.listTags.includes(tag)).length;
      return `${tag}: ${count}`;
    });

  console.log(`🏷️ Curated deck coverage -> ${counts.join(" | ")}`);
}

function compareProblemsById(left, right) {
  return (parseInt(left.id, 10) || 0) - (parseInt(right.id, 10) || 0);
}

function normalizeAcRate(value) {
  const numericValue = Number(value);
  if (!Number.isFinite(numericValue)) {
    return 0;
  }
  return Number(numericValue.toFixed(1));
}

function normalizeTag(value) {
  return String(value || "").trim().toLowerCase();
}

function uniqueTags(tags) {
  return [...new Set((tags || []).map(normalizeTag).filter(Boolean))];
}

function chunkArray(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

function getFlagValue(flag) {
  const index = args.indexOf(flag);
  if (index === -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

function getPositiveIntFlag(flag) {
  const rawValue = getFlagValue(flag);
  if (!rawValue) {
    return null;
  }

  const numericValue = Number.parseInt(rawValue, 10);
  return Number.isInteger(numericValue) && numericValue > 0 ? numericValue : null;
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
  const counts = buildListTagCounts(
    snap.docs.map((doc) => doc.data())
  );

  console.log(`\n📊 Firestore stats (${snap.size} total problems):`);
  Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .forEach(([tag, count]) => {
      const bar = "█".repeat(Math.floor(count / 2));
      console.log(`   ${tag.padEnd(16)} ${String(count).padStart(3)}  ${bar}`);
    });
  process.exit(0);
}

async function writeProblemCatalogMetadata(problems) {
  const counts = buildListTagCounts(problems);
  await db.collection("metadata").doc("problemCatalog").set({
    problemCount: problems.length,
    listTagStats: counts,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log("✅ Updated metadata/problemCatalog listTagStats.");
}

async function refreshMetadata() {
  const problems = await buildProblemCatalog();
  await writeProblemCatalogMetadata(problems);
  console.log(`✅ Refreshed metadata using ${problems.length} catalog entries.`);
  process.exit(0);
}

function buildListTagCounts(problems) {
  const counts = {};

  for (const problem of problems) {
    const tags = problem.listTags || [];
    for (const tag of tags) {
      counts[tag] = (counts[tag] || 0) + 1;
    }
  }

  return counts;
}

main().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});