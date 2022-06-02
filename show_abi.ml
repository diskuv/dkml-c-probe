#use "topfind";;
#require "dkml-c-probe";;

let abi = Lazy.force (Dkml_c_probe.C_abi.V3.get_abi) ;;
