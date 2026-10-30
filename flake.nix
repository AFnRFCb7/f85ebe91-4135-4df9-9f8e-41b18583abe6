{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { input ? null , output ? null } :
                        let
                            implementation =
                                { lib , pkgs , ... } @module :
                                    let
                                        identified =
                                            if builtins.typeOf input == "lambda" then input module
                                            else if builtins.typeOf input == "null" then module
                                            else builtins.throw "3659604674414346" ;
                                        in
                                            with identified ;
                                                {
                                                    options.sequential =
                                                        lib.mkOption
                                                            {
                                                                default =
                                                                    { sequential-file , sequential-lock } :
                                                                        pkgs.writeShellApplication
                                                                            {
                                                                                name = "sequential" ;
                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                text =
                                                                                    ''
                                                                                        SEQUENTIAL_DIRECTORY="$( dirname ${ sequential-lock } )" || failure 6285413743561461
                                                                                        mkdir --parents "$SEQUENTIAL_DIRECTORY"
                                                                                        exec 190> ${ sequential-lock }
                                                                                        flock -x 190
                                                                                        if [[ -f ${ sequential-file } ]]
                                                                                        then
                                                                                            CURRENT="$( cat ${ sequential-file } )" || failure 8469936118942842
                                                                                        else
                                                                                            CURRENT=0
                                                                                        fi
                                                                                        NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                                                        printf %016d "$NEXT"
                                                                                    '' ;
                                                                            } ;
                                                                type = lib.types.functionTo lib.types.package ;
                                                            } ;
                                                } ;
                            in
                                {
                                    check =
                                        {
                                            failure ?
                                                { pkgs , ... } @module :
                                                    let
                                                        identified =
                                                            if builtins.typeOf input == "lambda" then input module
                                                            else if builtins.typeOf input == "null" then module
                                                            else builtins.throw "3089158225937633" ;
                                                        in
                                                            with identified ;
                                                                {
                                                                    options.failure =
                                                                        lib.mkOption
                                                                            {
                                                                                default =
                                                                                    ignore :
                                                                                        pkgs.writeShellApplication
                                                                                            {
                                                                                                name = "failure" ;
                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        cat "$@" >&2
                                                                                                        exit 112
                                                                                                    '' ;
                                                                                            } ;
                                                                                type = lib.types.functionTo lib.types.package ;
                                                                            } ;
                                                                } ,
                                            nixosTest ,
                                            obviated-by ,
                                            visitor
                                        } :
                                        {
                                            initial ,
                                            expected ,
                                            sequential-file ,
                                            sequential-lock
                                        } :
                                            {
                                                obviated-by = obviated-by ;
                                                test =
                                                    nixosTest
                                                        {
                                                            name = "nixos-test" ;
                                                            nodes.client =
                                                                { config , lib , pkgs , ... } @module :
                                                                    let
                                                                        identified =
                                                                            if builtins.typeOf input == "lambda" then input module
                                                                            else if builtins.typeOf input == "null" then module
                                                                            else builtins.throw "2167550584726210" ;
                                                                        in
                                                                            with identified ;
                                                                                {
                                                                                    config.environment.systemPackages =
                                                                                        [
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "pre-test" ;
                                                                                                        runtimeInputs = [ ( config.failure { } ) pkgs.coreutils ] ;
                                                                                                        text =
                                                                                                            config.visitor
                                                                                                                { }
                                                                                                                {
                                                                                                                    int =
                                                                                                                        path : value :
                                                                                                                            ''
                                                                                                                                DIRECTORY="$( dirname ${ sequential-file } )" || failure 0966303434517646
                                                                                                                                mkdir --parents "$DIRECTORY"
                                                                                                                                echo ${ builtins.toString value } > ${ sequential-file }
                                                                                                                            '' ;
                                                                                                                    null = path : value : "" ;
                                                                                                                }
                                                                                                                initial ;
                                                                                                    }
                                                                                            )
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "test-script" ;
                                                                                                        runtimeInputs =
                                                                                                            [
                                                                                                                ( config.failure { } )
                                                                                                                ( config.sequential { sequential-file = sequential-file ; sequential-lock = sequential-lock ; } )
                                                                                                            ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                OBSERVED="$( sequential )" || failure 3444060292615108
                                                                                                                if [[ ${ lib.fixedWidthString 16 "0" ( builtins.toString expected ) } != "$OBSERVED" ]]
                                                                                                                then
                                                                                                                    failure 2963819842126200 ${ lib.fixedWidthString 16 "0" ( builtins.toString expected ) } "$OBSERVED"
                                                                                                                fi
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                                    imports = [ failure implementation visitor ] ;
                                                                                } ;
                                                            testScript =
                                                                ''
                                                                    client.wait_for_unit("multi-user.target")
                                                                    client.succeed("pre-test");
                                                                    client.succeed("test-script");
                                                                '' ;
                                                        } ;
                                                type = "sequential" ;
                                            } ;
                                    implementation =
                                        if builtins.typeOf output == "lambda" then output implementation
                                        else if builtins.typeOf output == "null" then implementation
                                        else builtins.throw "1045254547178996" ;
                                } ;
            } ;
}