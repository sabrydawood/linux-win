@echo off
Setlocal EnableDelayedExpansion
    if not exist .eslintrc.json (
        echo .eslintrc.json does not exist. Creating it...
        :: prettier
        echo { >> .eslintrc.json
        echo "root": true, >> .eslintrc.json
        echo "parserOptions": {  >> .eslintrc.json
        echo "ecmaVersion": "latest",  >> .eslintrc.json
        echo "sourceType": "module"  >> .eslintrc.json
        echo  }, >> .eslintrc.json
        echo "extends": ["eslint:recommended", "prettier"], >> .eslintrc.json
        echo "env": {   >> .eslintrc.json
        echo "es2021": true,  >> .eslintrc.json
        echo "node": true  >> .eslintrc.json
        echo },  >> .eslintrc.json
        echo "rules": {  >> .eslintrc.json
        echo "no-console": "off", >> .eslintrc.json
        echo "no-undefined": "off", >> .eslintrc.json
        echo "no-unused-vars": "warn">> .eslintrc.json
        echo },  >> .eslintrc.json
        echo "globals": { >> .eslintrc.json
        echo "describe": true, >> .eslintrc.json
        echo "it": true >> .eslintrc.json
        echo }  >> .eslintrc.json
        echo } >> .eslintrc.json
    ) else (
        echo .eslintrc.json already exists.
    )
        :: prettier
    if not exist .prettierrc.json (
        echo .prettierrc.json does not exist. Creating it...
        echo { >> .prettierrc.json
        echo "trailingComma": "es5", >> .prettierrc.json
        echo "tabWidth": 4, >> .prettierrc.json
        echo "semi": false, >> .prettierrc.json
        echo "singleQuote": true >> .prettierrc.json
        echo } >> .prettierrc.json
    ) else (
      echo .prettierrc.json already exists.
    )

:: ignore files
    if not exist .gitignore (
    echo .gitignore does not exist. Creating it...
    echo .eslintrc.json >> .gitignore
    echo .prettierrc.json >> .gitignore
    echo **/node_modules >> .gitignore
    echo **/dist >> .gitignore
    echo **/credentials >> .gitignore
    echo **/credentials-backup >> .gitignore
    echo **/new_credentials >> .gitignore
    echo **/logs >> .gitignore
    echo *.zip >> .gitignore
    echo *.rar >> .gitignore
    echo **/*.zip >> .gitignore
    echo **/*.rar >> .gitignore
    echo *.accdb >> .gitignore
    echo *.text >> .gitignore
    echo *.bat >> .gitignore
    echo *.cmd >> .gitignore
    echo report >> .gitignore
    ) else (
    echo .gitignore already exists.
)

:: prettier ignore 
    if not exist .prettierignore (
    echo .prettierignore does not exist. Creating it...
    echo .eslintrc.json >> .prettierignore
    echo .prettierrc.json >> .prettierignore
    echo build >> .prettierignore
    echo coverage >> .prettierignore
    echo credentials >> .prettierignore
    echo credentials-backup >> .prettierignore
    echo node_modules >> .prettierignore
    echo package-lock.json >> .prettierignore
    echo package.json >> .prettierignore
    echo prettierSetrup.bat >> .prettierignore
    echo **/node_modules >> .prettierignore
    echo **/dist >> .prettierignore
    echo **/credentials >> .prettierignore
    echo **/credentials-backup >> .prettierignore
    echo **/new_credentials >> .prettierignore
    echo **/logs >> .prettierignore
    echo *.zip >> .prettierignore
    echo *.rar >> .prettierignore
    echo **/*.zip >> .prettierignore
    echo **/*.rar >> .prettierignore
    echo *.accdb >> .prettierignore
    echo *.text >> .prettierignore
    echo *.bat >> .prettierignore
    echo *.cmd >> .prettierignore
    echo report >> .prettierignore
    ) else (
    echo .prettierignore already exists.
    )
endlocal
