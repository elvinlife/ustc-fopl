local util = require "sat_util"

-- print a table
function print_table(tbl)
	if tbl == nil then
		print("nil")
	else
		for k, v in pairs(tbl) do
			print(tostring(k)..": "..tostring(v))
		end
	end
end

-- return the size of a table
function size(tbl) 
	if tbl == nil then
		print("size nil")
		return 0
	end
	local cnt = 0
	for k, v in pairs(tbl) do
		cnt = cnt + 1
	end
	return cnt
end

--[[ This function takes in a list of atoms (variables) and a boolean expression
in conjunctive normal form. It should return a mapping from atom to booleans that
represents an assignment which satisfies the expression. If no assignments exist,
return nil. ]]--
function satisfiable(atoms, cnf)
    local function helper(assignment, clauses)
    -- Your code goes here.
    -- You may find util.deep_copy useful.
        if size(clauses) == 0 then
            for _, atom in pairs(atoms) do
                if assignment[atom] == nil then assignment[atom] = true end
            end
            return assignment
        end
        for _, clause in pairs(clauses[# clauses]) do
            local k = clause[1]
            local v = clause[2]
            if assignment[k] == nil or assignment[k] == v then
                local assignment = util.deep_copy(assignment)
                assignment[k] = v
                local head = util.deep_copy(clauses)
                head[# head] = nil
                local result = helper(assignment, head)
                if result ~= nil then return result end
            else
                return nil
            end
        end
        return nil 
    end
    return helper({}, cnf)
end


--[[ The function above only returns one solution. This function should return
an iterator which calculates, on demand, all of the solutions. ]]--
function satisfiable_gen(atoms, cnf)
	local function helper (assignment, clauses)
	  -- Your code goes here.
      -- You may find util.deep_copy useful.
        local function set_free_var(l, free_var)
            if # free_var == 0 then coroutine.yield(l)
            else
                local var = free_var[# free_var]
                local free_var_head = util.deep_copy(free_var)
                free_var_head[# free_var_head] = nil
                l[var] = true
                set_free_var(l, free_var_head)
                local l_ = util.deep_copy(l)
                l_[var] = false
                set_free_var(l_, free_var_head)
            end
        end
        if size(clauses) == 0 then
            local free_var = {}
            for _, atom in pairs(atoms) do
                if assignment[atom] == nil then table.insert(free_var, atom) end
            end
            set_free_var(assignment, free_var)
            return
        end
        for _, clause in pairs(clauses[size(clauses)]) do
            local k = clause[1]
            local v = clause[2]
            if assignment[k] == nil or assignment[k] == v then
                local assignment = util.deep_copy(assignment)
                assignment[k] = v
                local head = util.deep_copy(clauses)
                head[# head] = nil
                helper(assignment, head)
            end
        end
    end
	local solutions = coroutine.wrap(function ()
		helper({}, cnf)
	end)

	--[[ We've provided a wrapper which removes duplicate solutions so that
	your solver doesn't need to check for duplicates before emitting a result. ]]--
	return util.iter_dedup(solutions)
end

-- self test here
test_atom = {"a", "b", "c"}
test_cnf = {{{"a", true}, {"b", false}, {"c", true}}}
res = satisfiable(test_atom, test_cnf)
-- official test
util.run_basic_tests()
