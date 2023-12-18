return function(self,sandbox,code)
    local Sandbox = sandbox(self,getfenv(0))

    local func, err = loadstring(code)
    if err then
        return err
    end

    setfenv(func, Sandbox)
    task.defer(func)
end