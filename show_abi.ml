#use "topfind";;
#require "dkml-c-probe";;

let abi = Lazy.force (Dkml_c_probe.C_abi.V2.get_abi) ;;
