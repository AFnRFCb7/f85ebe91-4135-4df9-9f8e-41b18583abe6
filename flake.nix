{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        config-identity ? x : x ,
                        implementation-identity ? x : x ,
                        lib-identity ? x : x ,
                        pkgs-identity ? x : x
                    } :
                        let
                            implementation =
                                { lib , pkgs , ... } :
                                    let
                                        _lib = lib-identity lib ;
                                        _pkgs = pkgs-identity pkgs ;
                                        in
                                            {
                                                options.sequential =
                                                    _lib.mkOption
                                                        {
                                                            default =
                                                                { sequential-file , sequential-lock } :
                                                                    _pkgs.writeShellApplication
                                                                        {
                                                                            name = "sequential" ;
                                                                            runtimeInputs = [ _pkgs.coreutils ] ;
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
                                                            type = _lib.types.functionTo _lib.types.package ;
                                                        } ;
                                            } ;
                            in
                                {
                                    implementation = implementation-identity implementation ;
                                    check =
                                        {
                                            failure ,
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
                                                                { config , pkgs , ... } :
                                                                    let
                                                                        _config = config-identity config ;
                                                                        _pkgs = pkgs-identity pkgs ;
                                                                        in
                                                                            {
                                                                                config.environment.systemPackages =
                                                                                    [
                                                                                        (
                                                                                            _pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "pre-test" ;
                                                                                                    runtimeInputs = [ ( _config.failure { } ) _pkgs.coreutils ] ;
                                                                                                    text =
                                                                                                        _config.visitor
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
                                                                                            _pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "test-script" ;
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            ( _config.failure { } )
                                                                                                            ( _config.sequential { sequential-file = sequential-file ; sequential-lock = sequential-lock ; } )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            OBSERVED="$( sequential )" || failure 3444060292615108
                                                                                                            if [[ ${ builtins.fixedWithString 16 "0" ( builtins.toString expected ) } != "$OBSERVED" ]]
                                                                                                            then
                                                                                                                failure 2963819842126200 ${ builtins.fixedWithString 16 "0" ( builtins.toString expected ) } "$OBSERVED"
                                                                                                            fi
                                                                                                        '' ;
                                                                                                }
                                                                                        )
                                                                                    ] ;
                                                                                imports = [ failure implementation ] ;
                                                                            } ;
                                                            testScript =
                                                                ''
                                                                    client.wait_for_unit("multi-user.target")
                                                                    client.success("pre-test");
                                                                    client.success("test-script");
                                                                '' ;
                                                        } ;
                                                type = "sequential" ;
                                            } ;
                                } ;
            } ;
}