class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
        arr = {}

        for i, num in enumerate(nums):
            if target - num in arr:
                return [i, arr[target - num]]
            arr[num] = i
