--[[
This file is part of luax.

luax is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

luax is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with luax.  If not, see <https://www.gnu.org/licenses/>.

For further information about luax you can visit
http://cdelord.fr/luax
--]]

local S = require "String"

---------------------------------------------------------------------
-- Basic functions
---------------------------------------------------------------------

local function basic_functions()
    -- .. (concatenation)
    do
        eq("12".."".."345", "12345")
    end
    -- head
    do
        eq(S.head"abc", "a")
        eq(("abc"):head(), "a")
        eq(S.head"", nil)
        eq((""):head(), nil)
    end
    -- last
    do
        eq(S.last"abc", "c")
        eq(("abc"):last(), "c")
        eq(S.last"", nil)
        eq((""):last(), nil)
    end
    -- tail
    do
        eq(S.tail"456", "56")
        eq(("456"):tail(), "56")
        eq(S.tail"", nil)
        eq((""):tail(), nil)
    end
    -- init
    do
        eq(S.init"456", "45")
        eq(("456"):init(), "45")
        eq(S.init"", nil)
        eq((""):init(), nil)
    end
    -- init
    do
        eq({S.uncons"456"}, {"4", "56"})
        eq({("456"):uncons()}, {"4", "56"})
        eq({S.uncons""}, {nil, nil})
        eq({(""):uncons()}, {nil, nil})
    end
    -- null
    do
        eq(S.null"", true)
        eq((""):null(), true)
        eq(S.null"4", false)
        eq(("4"):null(), false)
        eq(S.null"45", false)
        eq(("45"):null(), false)
    end
    -- length
    do
        eq(S.length"", 0)
        eq((""):length(), 0)
        eq(S.length"4", 1)
        eq(("4"):length(), 1)
        eq(S.length"45", 2)
        eq(("45"):length(), 2)
    end
end

---------------------------------------------------------------------
-- List transformation
---------------------------------------------------------------------

local function list_transformations()
    -- map
    do
        -- map
        eq(S.map(string.upper, "abc"), {"A", "B", "C"})
        eq(("abc"):map(string.upper), {"A", "B", "C"})
        -- mapWithIndex
        eq(S.mapWithIndex(function(i, x) return x:byte()+i end, "0000"), {0x31, 0x32, 0x33, 0x34})
        eq(("0000"):mapWithIndex(function(i, x) return x:byte()+i end), {0x31, 0x32, 0x33, 0x34})
    end
    -- reverse
    do
        eq(S.reverse"", "")
        eq((""):reverse(), "")
        eq(S.reverse"456", "654")
        eq(("456"):reverse(), "654")
    end
    -- intersperse
    do
        eq(S.intersperse(",", "abc"), "a,b,c")
        eq((","):intersperse("abc"), "a,b,c")
        eq(S.intersperse(",", "a"), "a")
        eq((","):intersperse("a"), "a")
        eq(S.intersperse(",", ""), "")
        eq((""):intersperse(""), "")
    end
    -- intercalate
    do
        eq(S.intercalate(",", {"ab", "c", "de"}), "ab,c,de")
        eq((","):intercalate{"ab", "c", "de"}, "ab,c,de")
        eq(S.intercalate(",", {"ab"}), "ab")
        eq((","):intercalate{"ab"}, "ab")
    end
    -- subsequences
    do
        eq(S.subsequences"abc", {"", "a", "b", "ab", "c", "ac", "bc", "abc"})
        eq(("abc"):subsequences(), {"", "a", "b", "ab", "c", "ac", "bc", "abc"})
    end
    -- permutations
    do
        eq(S.permutations"abc", { "abc", "acb",
                                  "bac", "bca",
                                  "cba", "cab" })
        eq(("abc"):permutations(), { "abc", "acb",
                                     "bac", "bca",
                                     "cba", "cab" })
    end
end

---------------------------------------------------------------------
-- Reducing lists (folds)
---------------------------------------------------------------------

local function reducing_lists()
    -- foldl
    do
        eq(S.foldl(function(z, x) return x+z end, 0, "12345"), 0+1+2+3+4+5)
        eq(("12345"):foldl(function(z, x) return x+z end, 0), 0+1+2+3+4+5)
        eq(S.foldl(function(z, x) return x+z end, 0, ""), 0)
        eq((""):foldl(function(z, x) return x+z end, 0), 0)
    end
    -- foldl1
    do
        eq(S.foldl1(function(z, x) return x+z end, "12345"), 1+2+3+4+5)
        eq(("12345"):foldl1(function(z, x) return x+z end), 1+2+3+4+5)
        eq(S.foldl1(function(z, x) return x+z end, ""), nil)
        eq((""):foldl1(function(z, x) return x+z end), nil)
    end
    -- foldr
    do
        eq(S.foldr(function(x, z) return x+z end, 0, "12345"), 0+1+2+3+4+5)
        eq(("12345"):foldr(function(x, z) return x+z end, 0), 0+1+2+3+4+5)
        eq(S.foldr(function(x, z) return x+z end, 0, ""), 0)
        eq((""):foldr(function(x, z) return x+z end, 0), 0)
    end
    -- foldr1
    do
        eq(S.foldr1(function(x, z) return x+z end, "12345"), 1+2+3+4+5)
        eq(("12345"):foldr1(function(x, z) return x+z end), 1+2+3+4+5)
        eq(S.foldr1(function(x, z) return x+z end, ""), nil)
        eq((""):foldr1(function(x, z) return x+z end), nil)
    end
end

---------------------------------------------------------------------
-- Special folds
---------------------------------------------------------------------

local function special_folds()
    -- concat
    do
        eq(S.concat{"12", "", "345"}, "12345")
    end
    -- any
    do
        eq(S.any(function(x) return x > "3" end, ""), false)
        eq(S.any(function(x) return x > "3" end, "12"), false)
        eq(S.any(function(x) return x > "3" end, "1234"), true)
        eq(S.any(function(_) return true end, ""), false)
        eq((""):any(function(x) return x > "3" end), false)
        eq(("12"):any(function(x) return x > "3" end), false)
        eq(("1234"):any(function(x) return x > "3" end), true)
        eq((""):any(function(_) return true end), false)
    end
    -- all
    do
        eq(S.all(function(x) return x < "3" end, ""), true)
        eq(S.all(function(x) return x < "3" end, "12"), true)
        eq(S.all(function(x) return x < "3" end, "1234"), false)
        eq(S.all(function(_) return true end, ""), true)
        eq((""):all(function(x) return x < "3" end), true)
        eq(("12"):all(function(x) return x < "3" end), true)
        eq(("1234"):all(function(x) return x < "3" end), false)
        eq((""):all(function(_) return true end), true)
    end
    -- maximum
    do
        eq(S.maximum"123453012321", "5")
        eq(S.maximum"", nil)
        eq(("123453012321"):maximum(), "5")
        eq((""):maximum(), nil)
    end
    -- minimum
    do
        eq(S.minimum"123453012321", "0")
        eq(S.minimum"", nil)
        eq(("123453012321"):minimum(), "0")
        eq((""):minimum(), nil)
    end
end

---------------------------------------------------------------------
-- Building lists
---------------------------------------------------------------------

local function building_lists()
    -- scanl
    do
        eq(S.scanl(function(z, x) return z+x end, 0, "1234"), {0, 1, 3, 6, 10})
        eq(("1234"):scanl(function(z, x) return z+x end, 0), {0, 1, 3, 6, 10})
        eq(S.scanl(function(z, x) return z+x end, 0, ""), {0})
        eq((""):scanl(function(z, x) return z+x end, 0), {0})
    end
    -- scanl1
    do
        eq(S.scanl1(function(z, x) return z+x end, "1234"), {"1", 3, 6, 10})
        eq(("1234"):scanl1(function(z, x) return z+x end), {"1", 3, 6, 10})
        eq(S.scanl1(function(z, x) return z+x end, ""), {})
        eq((""):scanl1(function(z, x) return z+x end), {})
    end
    -- scanr
    do
        eq(S.scanr(function(x, z) return x+z end, 0, "1234"), {10, 9, 7, 4, 0})
        eq(("1234"):scanr(function(x, z) return x+z end, 0), {10, 9, 7, 4, 0})
        eq(S.scanr(function(x, z) return x+z end, 0, ""), {0})
        eq((""):scanr(function(x, z) return x+z end, 0), {0})
    end
    -- scanr1
    do
        eq(S.scanr1(function(x, z) return x+z end, "1234"), {10, 9, 7, "4"})
        eq(("1234"):scanr1(function(x, z) return x+z end), {10, 9, 7, "4"})
        eq(S.scanr1(function(x, z) return x+z end, ""), {})
        eq((""):scanr1(function(x, z) return x+z end), {})
    end
    -- replicate
    do
        eq(S.replicate(0, "42"), "")
        eq(S.replicate(-1, "42"), "")
        eq(S.replicate(1, "42"), "42")
        eq(S.replicate(4, "42"), "42424242")
    end
    -- unfoldr
    do
        eq(S.unfoldr(function(z) if z > "0" then return z, tostring(z-1) end end, "9"), "987654321")
        eq(S.unfoldr(function(z) if z > "0" then return z, tostring(z-1) end end, "1"), "1")
        eq(S.unfoldr(function(z) if z > "0" then return z, tostring(z-1) end end, "0"), "")
    end
end

---------------------------------------------------------------------
-- Sublists
---------------------------------------------------------------------

local function sublists()
    -- take
    do
        eq(S.take(3, "12345"), "123")
        eq(S.take(3, "12"), "12")
        eq(S.take(3, ""), "")
        eq(S.take(-1, "12"), "")
        eq(S.take(0, "12"), "")
        eq(("12345"):take(3), "123")
        eq(("12"):take(3), "12")
        eq((""):take(3), "")
        eq(("12"):take(-1), "")
        eq(("12"):take(0), "")
    end
    -- drop
    do
        eq(S.drop(3, "12345"), "45")
        eq(S.drop(3, "12"), "")
        eq(S.drop(3, ""), "")
        eq(S.drop(-1, "12"), "12")
        eq(S.drop(0, "12"), "12")
        eq(("12345"):drop(3), "45")
        eq(("12"):drop(3), "")
        eq((""):drop(3), "")
        eq(("12"):drop(-1), "12")
        eq(("12"):drop(0), "12")
    end
    -- splitAt
    do
        eq({S.splitAt(3, "12345")}, {"123", "45"})
        eq({S.splitAt(1, "123")}, {"1", "23"})
        eq({S.splitAt(3, "123")}, {"123", ""})
        eq({S.splitAt(4, "123")}, {"123", ""})
        eq({S.splitAt(0, "123")}, {"", "123"})
        eq({S.splitAt(-1, "123")}, {"", "123"})
        eq({("12345"):splitAt(3, "12345")}, {"123", "45"})
        eq({("123"):splitAt(1)}, {"1", "23"})
        eq({("123"):splitAt(3)}, {"123", ""})
        eq({("123"):splitAt(4)}, {"123", ""})
        eq({("123"):splitAt(0)}, {"", "123"})
        eq({("123"):splitAt(-1)}, {"", "123"})
    end
    -- takeWhile
    do
        eq(S.takeWhile(function(x) return x < "3" end, "12341234"), "12")
        eq(S.takeWhile(function(x) return x < "9" end, "123"), "123")
        eq(S.takeWhile(function(x) return x < "0" end, "123"), "")
        eq(("12341234"):takeWhile(function(x) return x < "3" end), "12")
        eq(("123"):takeWhile(function(x) return x < "9" end), "123")
        eq(("123"):takeWhile(function(x) return x < "0" end), "")
    end
    -- dropWhile
    do
        eq(S.dropWhile(function(x) return x < "3" end, "12345123"), "345123")
        eq(S.dropWhile(function(x) return x < "9" end, "123"), "")
        eq(S.dropWhile(function(x) return x < "0" end, "123"), "123")
        eq(("12345123"):dropWhile(function(x) return x < "3" end), "345123")
        eq(("123"):dropWhile(function(x) return x < "9" end), "")
        eq(("123"):dropWhile(function(x) return x < "0" end), "123")
    end
    -- dropWhileEnd
    do
        eq(S.dropWhileEnd(function(x) return x < "4" end, "12345123"), "12345")
        eq(S.dropWhileEnd(function(x) return x < "9" end, "123"), "")
        eq(S.dropWhileEnd(function(x) return x < "0" end, "123"), "123")
        eq(("12345123"):dropWhileEnd(function(x) return x < "4" end), "12345")
        eq(("123"):dropWhileEnd(function(x) return x < "9" end), "")
        eq(("123"):dropWhileEnd(function(x) return x < "0" end), "123")
    end
    -- span
    do
        eq({S.span(function(x) return x < "3" end, "12341234")}, {"12","341234"})
        eq({S.span(function(x) return x < "9" end, "123")}, {"123",""})
        eq({S.span(function(x) return x < "0" end, "123")}, {"","123"})
        eq({("12341234"):span(function(x) return x < "3" end)}, {"12","341234"})
        eq({("123"):span(function(x) return x < "9" end)}, {"123",""})
        eq({("123"):span(function(x) return x < "0" end)}, {"","123"})
    end
    -- break_
    do
        eq({S.break_(function(x) return x > "3" end, "12341234")}, {"123","41234"})
        eq({S.break_(function(x) return x > "9" end, "123")}, {"123",""})
        eq({S.break_(function(x) return x < "9" end, "123")}, {"","123"})
        eq({("12341234"):break_(function(x) return x > "3" end)}, {"123","41234"})
        eq({("123"):break_(function(x) return x > "9" end)}, {"123",""})
        eq({("123"):break_(function(x) return x < "9" end)}, {"","123"})
    end
    -- stripPrefix
    do
        eq(S.stripPrefix("12", "1234"), "34")
        eq(S.stripPrefix("12", "12"), "")
        eq(S.stripPrefix("32", "1234"), nil)
        eq(S.stripPrefix("", "1234"), "1234")
        eq(("1234"):stripPrefix("12"), "34")
        eq(("12"):stripPrefix("12"), "")
        eq(("1234"):stripPrefix("32"), nil)
        eq(("1234"):stripPrefix(""), "1234")
    end
    -- group
    do
        eq(S.group("Mississippi"), {"M","i","ss","i","ss","i","pp","i"})
        eq(S.group(""), {})
        eq(S.group("1"), {"1"})
        eq(("Mississippi"):group(), {"M","i","ss","i","ss","i","pp","i"})
        eq((""):group(), {})
        eq(("1"):group(), {"1"})
    end
    -- inits
    do
        eq(S.inits("123"), {"", "1", "12", "123"})
        eq(("123"):inits(), {"", "1", "12", "123"})
        eq(S.inits(""), {""})
        eq((""):inits(), {""})
    end
    -- tails
    do
        eq(S.tails("123"), {"123","23","3",""})
        eq(("123"):tails(), {"123","23","3",""})
        eq(S.tails(""), {""})
        eq((""):tails(), {""})
    end
end

---------------------------------------------------------------------
-- Predicates
---------------------------------------------------------------------

local function predicates()
    -- isPrefixOf
    do
        eq(S.isPrefixOf("12", "123"), true)
        eq(S.isPrefixOf("12", "132"), false)
        eq(S.isPrefixOf("", "123"), true)
        eq(S.isPrefixOf("12", ""), false)
        eq(("12"):isPrefixOf("123"), true)
        eq(("12"):isPrefixOf("132"), false)
        eq((""):isPrefixOf("123"), true)
        eq(("12"):isPrefixOf(""), false)
    end
    -- isSuffixOf
    do
        eq(S.isSuffixOf("12", "312"), true)
        eq(S.isSuffixOf("12", "321"), false)
        eq(S.isSuffixOf("", "123"), true)
        eq(S.isSuffixOf("12", ""), false)
        eq(("12"):isSuffixOf("312"), true)
        eq(("12"):isSuffixOf("321"), false)
        eq((""):isSuffixOf("123"), true)
        eq(("12"):isSuffixOf(""), false)
    end
    -- isInfixOf
    do
        eq(S.isInfixOf("12", "1234"), true)
        eq(S.isInfixOf("12", "3124"), true)
        eq(S.isInfixOf("12", "3412"), true)
        eq(S.isInfixOf("21", "1234"), false)
        eq(S.isInfixOf("21", "3124"), false)
        eq(S.isInfixOf("21", "3412"), false)
        eq(S.isInfixOf("", "1234"), true)
        eq(S.isInfixOf("12", ""), false)
        eq(("12"):isInfixOf("1234"), true)
        eq(("12"):isInfixOf("3124"), true)
        eq(("12"):isInfixOf("3412"), true)
        eq(("21"):isInfixOf("1234"), false)
        eq(("21"):isInfixOf("3124"), false)
        eq(("21"):isInfixOf("3412"), false)
        eq((""):isInfixOf("1234"), true)
        eq(("12"):isInfixOf(""), false)
    end
    -- isSubsequenceOf
    do
        eq(S.isSubsequenceOf("123", "0142536"), true)
        eq(S.isSubsequenceOf("123", "0143526"), false)
        eq(("123"):isSubsequenceOf("0142536"), true)
        eq(("123"):isSubsequenceOf("0143526"), false)
    end
end

---------------------------------------------------------------------
-- Searching lists
---------------------------------------------------------------------

local function searching_lists()
    -- elem
    do
        eq(S.elem("1", "123"), true)
        eq(S.elem("2", "123"), true)
        eq(S.elem("3", "123"), true)
        eq(S.elem("4", "123"), false)
        eq(S.elem("4", ""), false)
        eq(("123"):elem("1"), true)
        eq(("123"):elem("2"), true)
        eq(("123"):elem("3"), true)
        eq(("123"):elem("4"), false)
        eq((""):elem("4"), false)
    end
    -- notElem
    do
        eq(S.notElem("1", "123"), false)
        eq(S.notElem("2", "123"), false)
        eq(S.notElem("3", "123"), false)
        eq(S.notElem("4", "123"), true)
        eq(S.notElem("4", ""), true)
        eq(("123"):notElem("1"), false)
        eq(("123"):notElem("2"), false)
        eq(("123"):notElem("3"), false)
        eq(("123"):notElem("4"), true)
        eq((""):notElem("4"), true)
    end
    -- find
    do
        eq(S.find(function(x) return x > "3" end, "12345"), "4")
        eq(S.find(function(x) return x > "6" end, "12345"), nil)
        eq(S.find(function(_) return true end, ""), nil)
    end
    -- filter
    do
        eq(S.filter(function(x) return x%2==0 end, "12345"), "24")
        eq(S.filter(function(x) return x%2==0 end, ""), "")
        eq(("12345"):filter(function(x) return x%2==0 end), "24")
        eq((""):filter(function(x) return x%2==0 end), "")
    end
    -- partition
    do
        eq({S.partition(function(x) return x%2==0 end, "12345")}, {"24","135"})
        eq({S.partition(function(_) return true end, "12345")}, {"12345",""})
        eq({S.partition(function(_) return false end, "12345")}, {"","12345"})
        eq({S.partition(function(_) return true end, "")}, {"",""})
        eq({("12345"):partition(function(x) return x%2==0 end)}, {"24","135"})
        eq({("12345"):partition(function(_) return true end)}, {"12345",""})
        eq({("12345"):partition(function(_) return false end)}, {"","12345"})
        eq({(""):partition(function(_) return true end)}, {"",""})
    end
end

---------------------------------------------------------------------
-- Indexing lists
---------------------------------------------------------------------

local function indexing_lists()
    -- elemIndex
    do
        eq(S.elemIndex("2", "0123123"), 3)
        eq(("0123123"):elemIndex("2"), 3)
        eq(S.elemIndex("4", "0123123"), nil)
        eq(("0123123"):elemIndex("4"), nil)
    end
    -- elemIndices
    do
        eq(S.elemIndices("2", "0123123"), {3, 6})
        eq(("0123123"):elemIndices("2"), {3, 6})
        eq(S.elemIndices("4", "0123123"), {})
        eq(("0123123"):elemIndices("4"), {})
    end
    -- findIndex
    do
        eq(S.findIndex(function(x) return x=="2" end, "0123123"), 3)
        eq(("0123123"):findIndex(function(x) return x=="2" end), 3)
        eq(S.findIndex(function(x) return x=="4" end, "0123123"), nil)
        eq(("0123123"):findIndex(function(x) return x=="4" end), nil)
    end
    -- findIndices
    do
        eq(S.findIndices(function(x) return x=="2" end, "0123123"), {3, 6})
        eq(("0123123"):findIndices(function(x) return x=="2" end), {3, 6})
        eq(S.findIndices(function(x) return x=="4" end, "0123123"), {})
        eq(("0123123"):findIndices(function(x) return x=="4" end), {})
    end
end

---------------------------------------------------------------------
-- Functions on strings
---------------------------------------------------------------------

local function functions_on_strings()
    -- lines
    do
        eq(S.lines(""), {})
        eq(S.lines("\n"), {""})
        eq(S.lines("one"), {"one"})
        eq(S.lines("one\n"), {"one"})
        eq(S.lines("one\n\n"), {"one",""})
        eq(S.lines("one\ntwo"), {"one","two"})
        eq(S.lines("one\n\ntwo"), {"one","","two"})
        eq(S.lines("one\ntwo\n"), {"one","two"})
    end
    -- words
    do
        eq(S.words(""), {})
        eq(S.words("\n"), {})
        eq(S.words("one"), {"one"})
        eq(S.words("one\n"), {"one"})
        eq(S.words("one\n\n"), {"one"})
        eq(S.words("one\ntwo"), {"one","two"})
        eq(S.words("one\n\ntwo"), {"one","two"})
        eq(S.words("one\ntwo\n"), {"one","two"})
        eq(S.words(" Lorem ipsum\ndolor "), {"Lorem","ipsum","dolor"})
    end
    -- unlines
    do
        eq(S.unlines{}, "")
        eq(S.unlines{""}, "\n")
        eq(S.unlines{"one"}, "one\n")
        eq(S.unlines{"one",""}, "one\n\n")
        eq(S.unlines{"one","two"}, "one\ntwo\n")
        eq(S.unlines{"one","","two"}, "one\n\ntwo\n")
    end
    -- unwords
    do
        eq(S.unwords{}, "")
        eq(S.unwords{""}, "")
        eq(S.unwords{"one"}, "one")
        eq(S.unwords{"one","two"}, "one two")
    end
end

---------------------------------------------------------------------
-- Set operations
---------------------------------------------------------------------

local function set_operations()
    -- nub
    do
        eq(S.nub"12343212435", "12345")
        eq(("12343212435"):nub(), "12345")
    end
    -- delete
    do
        eq(S.delete('a', 'banana'), 'bnana')
        eq(S.delete('c', 'banana'), 'banana')
        eq(S.delete('c', ""), "")
        eq(('banana'):delete('a'), 'bnana')
        eq(('banana'):delete('c'), 'banana')
        eq((""):delete('c'), "")
    end
    -- difference
    do
        eq(S.difference("123123", "12"), "3123")
        eq(S.difference("123123", "21"), "3123")
        eq(S.difference("123123", "23"), "1123")
        eq(S.difference("123123", "23"), "1123")
        eq(("123123"):difference"12", "3123")
        eq(("123123"):difference"21", "3123")
        eq(("123123"):difference"23", "1123")
        eq(("123123"):difference"23", "1123")
    end
    -- union
    do
        eq(S.union("1231","234235234235"), "123145")
        eq(S.union("1231",""), "1231")
        eq(S.union("","234235234235"), "2345")
        eq(("1231"):union"234235234235", "123145")
        eq(("1231"):union"", "1231")
        eq((""):union"234235234235", "2345")
    end
    -- intersect
    do
        eq(S.intersect("123132","234235234235"), "2332")
        eq(S.intersect("1231",""), "")
        eq(S.intersect("","234235234235"), "")
        eq(("123132"):intersect"234235234235", "2332")
        eq(("1231"):intersect"", "")
        eq((""):intersect"234235234235", "")
    end
end

---------------------------------------------------------------------
-- Ordered lists
---------------------------------------------------------------------

local function ordered_lists()
    -- sort
    do
        eq(S.sort"164325", "123456")
        eq(("164325"):sort(), "123456")
    end
    -- sortOn
    do
        local function fst(xs) return xs[1] end
        eq(S.sortOn(string.upper, "Hello World!"), " !deHllloorW")
        eq(("Hello World!"):sortOn(string.upper), " !deHllloorW")
    end
    -- insert
    do
        eq(S.insert("4", "123567"), "1234567")
        eq(S.insert("0", "123567"), "0123567")
        eq(S.insert("8", "123567"), "1235678")
        eq(("123567"):insert("4"), "1234567")
        eq(("123567"):insert("0"), "0123567")
        eq(("123567"):insert("8"), "1235678")
    end
end

---------------------------------------------------------------------
-- Generalized functions
---------------------------------------------------------------------

local function generalized_functions()
    -- nubBy
    do
        local function case(a, b) return a:lower() == b:lower() end
        eq(S.nubBy(case, "aABb"), "aB")
        eq(("aABb"):nubBy(case), "aB")
    end
    -- deleteBy
    do
        local function eqchar(a, b) return a:lower() == b:lower() end
        eq(S.deleteBy(eqchar, 'a', 'bAnana'), 'bnana')
        eq(S.deleteBy(eqchar, 'c', 'bAnana'), 'bAnana')
        eq(S.deleteBy(eqchar, 'c', ''), '')
        eq(('bAnana'):deleteBy(eqchar, 'a'), 'bnana')
        eq(('bAnana'):deleteBy(eqchar, 'c'), 'bAnana')
        eq((''):deleteBy(eqchar, 'c', ''), '')
    end
    -- differenceBy
    do
        local function eqmod2(a, b) return tonumber(a)%2 == tonumber(b)%2 end
        eq(S.differenceBy(eqmod2, "123123", "12"), "3123")
        eq(S.differenceBy(eqmod2, "123123", "21"), "3123")
        eq(S.differenceBy(eqmod2, "123123", "23"), "3123")
        eq(S.differenceBy(eqmod2, "123123", "23"), "3123")
        eq(("123123"):differenceBy(eqmod2, "12"), "3123")
        eq(("123123"):differenceBy(eqmod2, "21"), "3123")
        eq(("123123"):differenceBy(eqmod2, "23"), "3123")
        eq(("123123"):differenceBy(eqmod2, "23"), "3123")
    end
    -- unionBy
    do
        local function eqmod2(a, b) return tonumber(a)%2 == tonumber(b)%2 end
        eq(S.unionBy(eqmod2, "1231","234235234235"), "1231")
        eq(S.unionBy(eqmod2, "1231",""), "1231")
        eq(S.unionBy(eqmod2, "","234235234235"), "23")
        eq(("1231"):unionBy(eqmod2, "234235234235"), "1231")
        eq(("1231"):unionBy(eqmod2, ""), "1231")
        eq((""):unionBy(eqmod2, "234235234235"), "23")
    end
    -- intersectBy
    do
        local function eqmod2(a, b) return tonumber(a)%2 == tonumber(b)%2 end
        eq(S.intersectBy(eqmod2, "123132","234235234235"), "123132")
        eq(S.intersectBy(eqmod2, "1231",""), "")
        eq(S.intersectBy(eqmod2, "","234235234235"), "")
        eq(("123132"):intersectBy(eqmod2, "234235234235"), "123132")
        eq(("1231"):intersectBy(eqmod2, ""), "")
        eq((""):intersectBy(eqmod2, "234235234235"), "")
    end
    -- groupBy
    do
        local function eqmod2(a, b) return a:byte()%2 == b:byte()%2 end
        eq(S.groupBy(eqmod2, "Mississippi"), {"Mississi","pp","i"})
        eq(S.groupBy(eqmod2, "Mississippii"), {"Mississi","pp","ii"})
        eq(S.groupBy(eqmod2, ""), {})
        eq(("Mississippi"):groupBy(eqmod2), {"Mississi","pp","i"})
        eq(("Mississippii"):groupBy(eqmod2), {"Mississi","pp","ii"})
        eq((""):groupBy(eqmod2), {})
    end
    -- sortBy
    do
        local function ge(a, b) return a >= b end
        eq(S.sortBy(ge, "164325"), "654321")
        eq(("164325"):sortBy(ge), "654321")
    end
    -- insertBy
    do
        local function le(a, b) return a <= b end
        eq(S.insertBy(le, "4", "123567"), "1234567")
        eq(S.insertBy(le, "0", "123567"), "0123567")
        eq(S.insertBy(le, "8", "123567"), "1235678")
        eq(("123567"):insertBy(le, "4"), "1234567")
        eq(("123567"):insertBy(le, "0"), "0123567")
        eq(("123567"):insertBy(le, "8"), "1235678")
    end
    -- maximumBy
    do
        local function le(a, b) return a <= b end
        eq(S.maximumBy(le, "123453012321"), "5")
        eq(S.maximumBy(le, ""), nil)
        eq(("123453012321"):maximumBy(le), "5")
        eq((""):maximumBy(le), nil)
    end
    -- minimumBy
    do
        local function le(a, b) return a <= b end
        eq(S.minimumBy(le, "123453012321"), "0")
        eq(S.minimumBy(le, ""), nil)
        eq(("123453012321"):minimumBy(le), "0")
        eq((""):minimumBy(le), nil)
    end
end

---------------------------------------------------------------------
-- Run all tests
---------------------------------------------------------------------

return function()
    basic_functions()
    list_transformations()
    reducing_lists()
    special_folds()
    building_lists()
    sublists()
    predicates()
    searching_lists()
    indexing_lists()
    functions_on_strings()
    set_operations()
    ordered_lists()
    generalized_functions()
end
