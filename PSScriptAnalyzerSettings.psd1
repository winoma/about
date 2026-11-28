# PSScriptAnalyzer settings for this repository.
# Used by .github/workflows/psscriptanalyzer.yml and by local runs:
#   Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # WinOma Scan is an interactive console tool: coloured Write-Host output is intended.
        'PSAvoidUsingWriteHost',
        # Script-level switches such as -NoPause are read inside functions, which the rule does not follow.
        'PSReviewUnusedParameter',
        # Internal helpers (Set-Result, Start-Area) only touch in-memory state, never the system.
        'PSUseShouldProcessForStateChangingFunctions',
        # Internal display helpers (Show-Areas, Show-Fixes ...) are not exported cmdlets.
        'PSUseSingularNouns'
    )
}
