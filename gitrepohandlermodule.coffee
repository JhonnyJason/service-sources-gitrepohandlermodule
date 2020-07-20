githandlermodule = {name: "githandlermodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["githandlermodule"]?  then console.log "[githandlermodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
#region node_modules
fs = require("fs-extra")
git = require("simple-git/promise")
pathModule = require("path")
#endregion

############################################################
#region internalProperties
rootDir = ""
repoDir = ""

upstreamremote = ""
#endregion

############################################################
githandlermodule.initialize = () ->
    log "githandlermodule.initialize"
    c = allModules.configmodule
    upstreamremote = 'https://' + c.user + ':' + c.pass + '@' + c.contentRepo

    rootDir = pathModule.resolve(process.cwd(), c.gitRootPath)
    repoDir = pathModule.resolve(process.cwd(), c.contentRepoPath)
    return
    
############################################################
#region internalFunctions
tryPull = ->
    log "tryPull"
    try
        result = await git(repoDir).pull("origin", "master")
        log JSON.stringify(result)
    catch err
        fs.removeSync(repoDir)
        doInitialClone()
    return

doInitialClone = ->
    log "doInitialClone"
    result = await git(rootDir).clone(upstreamremote)
    log JSON.stringify(result)
    return
    
#endregion

############################################################
#region exposedFunctions
githandlermodule.pullContents = ->
        log "githandlermodule.pullContents"
        await tryPull()
        return

githandlermodule.pushContents = ->
        log "githandlermodule.pushContents"
        result = ""
        try 
            result = await git(repoDir).add(".")
            log result
            result = await git(repoDir).commit("automated commit by the service-sources-gitrepohandlermodule")
            log result
            result = await git(repoDir).push("origin", "master")
            log result
        catch error then log error
        return

githandlermodule.startupCheck = ->
    log "githandlermodule.startupCheck"
    if fs.existsSync(repoDir) then await tryPull()
    else await doInitialClone()
    return

#endregion

module.exports = githandlermodule