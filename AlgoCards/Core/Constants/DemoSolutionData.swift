//
//  DemoSolutionData.swift
//  AlgoCards
//
// Local demo-only fallback solutions for a fixed set of well-known problems.
// Shown only when the official solution API returns no usable content.
// Keys must match ProblemListItem.titleSlug exactly (case-sensitive).
// Safe to delete after the project is complete.

import Foundation

enum DemoSolutionData {

    // Keys are LeetCode titleSlug values — must match Firestore / ProblemListItem.titleSlug exactly.
    static let solutions: [String: String] = [

        "two-sum":
            """
            Hash Map (One Pass)

            Goal: find two indices i, j such that nums[i] + nums[j] == target.

            Iterate through the array. For each element x, compute complement = target - x.
            Check if complement is already stored in the hash map:
              - Yes: return [map[complement], currentIndex].
              - No:  store x -> currentIndex and continue.

            Why it works: every element is checked against all previously seen elements in O(1)
            lookup time, so no nested loop is needed.

            Time: O(n)  |  Space: O(n)
            """,

        "valid-parentheses":
            """
            Stack

            Maintain a stack of unmatched opening brackets.

            For each character in the string:
              - Opening bracket ( [ {  -> push onto the stack.
              - Closing bracket ) ] }  -> if the stack is empty or the top does not match,
                return false; otherwise pop the top.

            After the loop, return true only when the stack is empty
            (every opener was matched and closed in order).

            Time: O(n)  |  Space: O(n)
            """,

        "best-time-to-buy-and-sell-stock":
            """
            Greedy One Pass

            Track two variables: minPrice (lowest price seen so far) and maxProfit (best
            profit achievable so far). Start with minPrice = +infinity, maxProfit = 0.

            For each daily price p:
              minPrice  = min(minPrice, p)
              maxProfit = max(maxProfit, p - minPrice)

            Since minPrice is always to the left of the current day, this never looks
            into the future and correctly handles all buy-before-sell constraints.

            Return maxProfit (0 if prices only decrease).

            Time: O(n)  |  Space: O(1)
            """,

        "maximum-subarray":
            """
            Kadane's Algorithm

            Maintain two values: currentSum (best subarray ending here) and maxSum (global best).

            For each element num:
              currentSum = max(num, currentSum + num)
              maxSum     = max(maxSum, currentSum)

            The first line decides: is it better to start a fresh subarray at num, or to
            extend the previous one? If currentSum was negative, extending would hurt, so
            we reset to num itself.

            Time: O(n)  |  Space: O(1)
            """,

        "climbing-stairs":
            """
            Dynamic Programming (Fibonacci Variant)

            To reach step n you must have come from step n-1 (one step) or step n-2 (two steps):
              ways(n) = ways(n-1) + ways(n-2)

            Base cases: ways(1) = 1, ways(2) = 2.

            Rather than building the whole DP table, keep only the previous two values
            and update them in a loop — this reduces space to O(1).

            Time: O(n)  |  Space: O(1)
            """,

        "reverse-linked-list":
            """
            Iterative Three-Pointer Reversal

            Use three pointers: prev (initially nil), curr (head), next (scratch space).

            While curr is not nil:
              1. Save  next = curr.next         (preserve the rest of the list)
              2. Flip  curr.next = prev          (reverse the current link)
              3. Advance: prev = curr, curr = next

            When the loop ends, prev points to the new head.

            Time: O(n)  |  Space: O(1)
            """,

        "merge-two-sorted-lists":
            """
            Iterative Merge with Dummy Head

            Create a dummy node as the result list's anchor. Keep a tail pointer at the
            last node appended.

            While both lists are non-empty:
              - Compare list1.val and list2.val.
              - Attach the smaller node to tail.next and advance that list's pointer.
              - Advance tail.

            After the loop, at most one list still has nodes — attach it directly to tail.next.

            Return dummy.next as the merged head.

            Time: O(m + n)  |  Space: O(1)
            """,

        "binary-search":
            """
            Classic Divide and Conquer

            Maintain lo = 0 and hi = nums.length - 1.

            While lo <= hi:
              mid = lo + (hi - lo) / 2   // avoids integer overflow
              if nums[mid] == target  -> return mid
              if nums[mid] < target   -> lo = mid + 1  (target is in the right half)
              if nums[mid] > target   -> hi = mid - 1  (target is in the left half)

            Return -1 when the loop exits — target is not in the array.

            Time: O(log n)  |  Space: O(1)
            """,

        "contains-duplicate":
            """
            Hash Set

            Insert each element into a hash set as you iterate.
            If the element is already present, return true immediately — a duplicate exists.
            If the loop completes without a hit, return false.

            Alternative O(1) extra space approach: sort the array first, then check adjacent
            elements. Trade-off: O(n log n) time vs O(n) time with hash set.

            Time: O(n)  |  Space: O(n)
            """,

        "product-of-array-except-self":
            """
            Two-Pass Prefix / Suffix Products

            The result for index i is the product of all elements to its left times the
            product of all elements to its right.

            Pass 1 (left to right): fill result[i] with the running product of nums[0..i-1].
            Pass 2 (right to left): multiply result[i] by the running product of nums[i+1..n-1].

            No division is used and only one output array of size n is needed beyond the input.

            Time: O(n)  |  Space: O(1) extra (output array not counted)
            """,

        // ── LeetCode #2 ──────────────────────────────────────────────────────────
        "add-two-numbers":
            """
            Simulated Addition with Carry

            Traverse both lists simultaneously, summing corresponding digits plus the carry
            from the previous position. Create a new node for each digit of the result
            (sum % 10) and pass carry = sum / 10 to the next iteration.

            Continue until both lists are exhausted and carry == 0.
            A dummy head node simplifies edge cases at the start of the result list.

            Time: O(max(m, n))  |  Space: O(max(m, n))
            """,

        // ── LeetCode #3 ──────────────────────────────────────────────────────────
        "longest-substring-without-repeating-characters":
            """
            Sliding Window

            Maintain a window [left, right] and a hash map that records the most recent
            index of each character.

            Expand right one step at a time. If the new character already exists inside
            the current window, jump left to one past its last seen position (do not just
            move left by one — skip directly to avoid re-processing).

            Track the maximum window length seen throughout.

            Time: O(n)  |  Space: O(min(n, alphabet size))
            """,

        // ── LeetCode #4 ──────────────────────────────────────────────────────────
        "median-of-two-sorted-arrays":
            """
            Binary Search on the Smaller Array

            Partition both arrays so that the combined left half holds exactly half of all
            elements. Binary search on the shorter array to find the correct cut point.

            At a valid partition: maxLeft1 <= minRight2  AND  maxLeft2 <= minRight1.
            The median is then determined by the four boundary values.

            Adjust the search range left or right based on which boundary condition fails.

            Time: O(log(min(m, n)))  |  Space: O(1)
            """,

        // ── LeetCode #5 ──────────────────────────────────────────────────────────
        "longest-palindromic-substring":
            """
            Expand Around Center

            A palindrome mirrors around its center. There are 2n - 1 possible centers
            (each character and each gap between characters).

            For every center, expand outward as long as the characters on both sides match.
            Record the start index and length of the longest palindrome found.

            Simpler than DP and equally efficient for this problem size.

            Time: O(n²)  |  Space: O(1)
            """,

        // ── LeetCode #10 ─────────────────────────────────────────────────────────
        "regular-expression-matching":
            """
            2D Dynamic Programming

            dp[i][j] = true if pattern[0..j-1] matches string[0..i-1].

            Base case: dp[0][0] = true (empty pattern matches empty string).
            Seed the first row for patterns like "a*b*" that can match an empty string.

            Transition:
              - If pattern[j-1] is a letter or '.': dp[i][j] = dp[i-1][j-1] AND chars match.
              - If pattern[j-1] is '*':
                  - Zero occurrences: dp[i][j] = dp[i][j-2].
                  - One or more: dp[i][j] |= dp[i-1][j] AND preceding element matches s[i-1].

            Time: O(m * n)  |  Space: O(m * n)
            """,

        // ── LeetCode #11 ─────────────────────────────────────────────────────────
        "container-with-most-water":
            """
            Two Pointers

            Start with left = 0 and right = n - 1 (widest possible container).
            At each step: area = min(height[left], height[right]) * (right - left).
            Update the running maximum.

            Always move the pointer with the shorter bar inward.
            Rationale: the shorter bar is the limiting factor; moving the taller one can
            only reduce width without any chance of gaining height.

            Time: O(n)  |  Space: O(1)
            """,

        // ── LeetCode #15 ─────────────────────────────────────────────────────────
        "3sum":
            """
            Sort + Two Pointers

            Sort the array. Iterate with index i from 0 to n-3.
            For each nums[i], use two pointers (lo = i+1, hi = n-1) to find pairs
            summing to -nums[i]:
              - Sum == 0: record the triplet, then advance both pointers past duplicates.
              - Sum < 0:  lo++ (need a larger value).
              - Sum > 0:  hi-- (need a smaller value).

            Skip duplicate values of nums[i] to avoid duplicate triplets in the output.

            Time: O(n²)  |  Space: O(1) extra
            """,

        // ── LeetCode #19 ─────────────────────────────────────────────────────────
        "remove-nth-node-from-end-of-list":
            """
            Two Pointers (Fixed Gap)

            Use a dummy head node before the real head to handle edge cases cleanly.
            Set fast and slow both to dummy.

            Advance fast exactly n + 1 steps ahead of slow.
            Then move both pointers one step at a time until fast reaches nil.
            Now slow.next is the node to remove — set slow.next = slow.next.next.

            The n + 1 gap ensures slow lands on the node before the target, not on it.

            Time: O(L)  |  Space: O(1)
            """
    ]
}
