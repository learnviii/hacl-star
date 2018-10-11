module Hacl.Hash.SHA1

open Hacl.Hash.Definitions
open Spec.Hash.Helpers

include Hacl.Hash.Core.SHA1

val update_multi: update_multi_st SHA1
val update_last: update_last_st SHA1
val hash: hash_st SHA1
