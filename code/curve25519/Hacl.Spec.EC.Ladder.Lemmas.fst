module Hacl.Spec.EC.Ladder.Lemmas

open Spec.Curve25519
open FStar.UInt8

#reset-options "--max_fuel 0"

val small_loop_step:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:t ->
  Tot (proj_point * proj_point)
let small_loop_step q nq nqpq b =
  let bit = (v b / pow2 7) % 2 in
  if bit = 1 then
    let (a, b) = Spec.Curve25519.add_and_double q nqpq nq in (b, a)
  else Spec.Curve25519.add_and_double q nq nqpq


#reset-options "--max_fuel 0 --z3rlimit 20"

val double_step:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:t ->
  Tot (proj_point * proj_point)
let double_step q nq nqpq b =
  let nq', nqpq' = small_loop_step q nq nqpq b in
  let b' = b <<^ 1ul in
  small_loop_step q nq' nqpq' b'


val small_loop:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  ctr:nat{ctr <= 4} ->
  Tot (proj_point * proj_point)
      (decreases ctr)
let rec small_loop q nq nqpq b ctr =
  if ctr = 0 then (nq, nqpq)
  else (
    let ctr' = ctr - 1 in
    let nq', nqpq' = double_step q nq nqpq b in
    let b' = b <<^ 2ul in
    small_loop q nq' nqpq' b' ctr'
  )

#reset-options "--initial_fuel 1 --max_fuel 1"

val lemma_small_loop_def_0: q:elem -> nq:proj_point -> nqpq:proj_point -> b:byte -> Lemma
  (small_loop q nq nqpq b 0 == (nq, nqpq))
let lemma_small_loop_def_0 q nq nqpq b = ()


#reset-options "--max_fuel 0 --z3rlimit 20"

val lemma_small_loop_def_1: q:elem -> nq:proj_point -> nqpq:proj_point -> b:byte -> ctr:nat{ctr <= 4 /\ ctr > 0} -> Lemma (small_loop q nq nqpq b ctr ==  (let ctr' = ctr - 1 in
                                               let nq', nqpq' = double_step q nq nqpq b in
                                               let b' = b <<^ 2ul in
                                               small_loop q nq' nqpq' b' ctr'))
#reset-options "--initial_fuel 1 --max_fuel 1"
let lemma_small_loop_def_1 q nq nqpq b ctr = ()


#reset-options "--max_fuel 0 --z3rlimit 20"

val small_loop_unrolled:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  Tot (proj_point * proj_point)
let small_loop_unrolled q nq nqpq b =
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  let nq, nqpq = double_step q nq nqpq b in
  nq, nqpq

val lemma_small_loop_unrolled:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  Lemma (small_loop_unrolled q nq nqpq b == small_loop q nq nqpq b 4)
let lemma_small_loop_unrolled q nq nqpq b =
  lemma_small_loop_def_1 q nq nqpq b 4;
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  lemma_small_loop_def_1 q nq nqpq b 3;
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  lemma_small_loop_def_1 q nq nqpq b 2;
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  lemma_small_loop_def_1 q nq nqpq b 1;
  let nq, nqpq = double_step q nq nqpq b in
  let b = b <<^ 2ul in
  lemma_small_loop_def_0 q nq nqpq b


val lemma_shift_1l: b:byte -> i:UInt32.t -> j:UInt32.t{UInt32.v i + UInt32.v j < 8} -> Lemma (((b <<^ i) <<^ j) == (b <<^ (FStar.UInt32.(i +^ j))))
let lemma_shift_1l b i j =
  let open FStar.Mul in
  let vb = v b in
  let bi = v (b <<^ i) in
  let bij = v ((b <<^ i) <<^ j) in
  let i = UInt32.v i in
  let j = UInt32.v j in
  cut (bi = (vb * pow2 (i)) % pow2 8);
  cut (bij = (((vb * pow2 (i)) % pow2 8) * pow2 (j)) % pow2 8);
  // (vb * pow2 (i+j)) % pow2 8
  Math.Lemmas.pow2_multiplication_modulo_lemma_2 (v b * pow2 (i)) (8+ j) j;
  cut (((vb * pow2 (i)) % pow2 8) * pow2 (j) = (((v b * pow2 (i)) * (pow2 j))) % pow2 (8 + j));
  Math.Lemmas.paren_mul_right (v b) (pow2 i) (pow2 j);
  Math.Lemmas.pow2_plus i j;
  cut (((vb * pow2 (i)) % pow2 8) * pow2 (j) = (v b * pow2 (i+j)) % pow2 (8 + j));
  Math.Lemmas.pow2_modulo_modulo_lemma_1 (v b * pow2 (i+j)) 8 (8 + j)
  

val small_loop_unrolled2:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  Tot (proj_point * proj_point)
let small_loop_unrolled2 q nq nqpq b =
  let nq, nqpq = small_loop_step q nq nqpq b in
  let b' = b <<^ 1ul in
  let nq, nqpq = small_loop_step q nq nqpq b' in
  let b = b <<^ 2ul in
  let nq, nqpq = small_loop_step q nq nqpq b in
  let b' = b <<^ 1ul in
  let nq, nqpq = small_loop_step q nq nqpq b' in
  let b = b <<^ 2ul in
  let nq, nqpq = small_loop_step q nq nqpq b in
  let b' = b <<^ 1ul in
  let nq, nqpq = small_loop_step q nq nqpq b' in
  let b = b <<^ 2ul in
  let nq, nqpq = small_loop_step q nq nqpq b in
  let b' = b <<^ 1ul in
  let nq, nqpq = small_loop_step q nq nqpq b' in
  nq, nqpq


val lemma_small_loop_unrolled2:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  Lemma (small_loop_unrolled2 q nq nqpq b == small_loop q nq nqpq b 4)
let lemma_small_loop_unrolled2 q nq nqpq b =
  lemma_small_loop_unrolled q nq nqpq b


val small_loop_unrolled3:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  Tot (proj_point * proj_point)
let small_loop_unrolled3 q nq nqpq b =
  let nq, nqpq = small_loop_step q nq nqpq b in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 1ul) in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 2ul) in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 3ul) in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 4ul) in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 5ul) in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 6ul) in
  let nq, nqpq = small_loop_step q nq nqpq (b <<^ 7ul) in
  nq, nqpq


val lemma_small_loop_unrolled3:
  q:elem ->
  nq:proj_point ->
  nqpq:proj_point ->
  b:byte ->
  Lemma (small_loop_unrolled3 q nq nqpq b == small_loop q nq nqpq b 4)
#reset-options "--max_fuel 0 --z3rlimit 50"
let lemma_small_loop_unrolled3 q nq nqpq b =
  let b0 = b in
  lemma_shift_1l b0 2ul 1ul;
  lemma_shift_1l b0 2ul 2ul;
  lemma_shift_1l b0 4ul 1ul;
  lemma_shift_1l b0 4ul 2ul;
  lemma_shift_1l b0 6ul 1ul;
  lemma_small_loop_unrolled2 q nq nqpq b


val lemma_byte_bit: b:byte -> n:UInt32.t{UInt32.v n < 8} -> 
  Lemma (v ((b <<^ n) >>^ 7ul) % 2 = (v b / pow2 (7 - UInt32.v n)) % 2)
let lemma_byte_bit b n =
  let open FStar.Mul in
  let vb = v b in
  let vbn = v (b <<^ n) in
  let vbn7 = v ((b <<^ n) >>^ 7ul) in
  let n = UInt32.v n in
  cut (vbn = (v b * pow2 n) % pow2 8);
  cut (vbn7 = (vbn / pow2 7) % pow2 8);
  Math.Lemmas.pow2_modulo_division_lemma_1 vbn 7 8;
  cut (vbn7 = (vbn % pow2 8) / pow2 7);
  Math.Lemmas.modulo_lemma vbn (pow2 8);
  cut (vbn = (vbn % pow2 8));
  cut (vbn7 = vbn / pow2 7);
  Math.Lemmas.pow2_modulo_division_lemma_1 (vb * pow2 n) 7 8;
  cut (vbn7 = ((vb * pow2 n) / pow2 7) % pow2 1);
  Math.Lemmas.pow2_multiplication_division_lemma_2 vb 7 n;
  cut (((vb * pow2 n) / pow2 7) = vb / (pow2 (7 - n)));
  Math.Lemmas.modulo_lemma ((vb / (pow2 (7 - n))) % pow2 1) (pow2 1);
  assert_norm(pow2 1 = 2)



(* val lemma_byte_bit: k:nat -> b:byte -> i:nat -> j:nat{j < 8} -> Lemma *)
(*   (requires (let open FStar.Mul in v b = (((k / pow2 (8 * i)) % pow2 8) * pow2 j) % pow2 8)) *)
(*   (ensures (let open FStar.Mul in (v b / pow2 7) % 2 = (k / pow2 (8 * i + j)) % 2)) *)
(* #reset-options "--max_fuel 0 --z3rlimit 100" *)
(* let lemma_byte_bit k b i j = *)
(*   let open FStar.Mul in *)
(*   let b0 = ((k / pow2 (8 * i)) % pow2 8) in *)
(*   let b0j = b0 * pow2 j in *)
(*   let vb = b0j % pow2 8 in *)
(*   Math.Lemmas.pow2_modulo_division_lemma_1 b0j 7 8; *)
(*   cut (vb / pow2 7 = (b0j / pow2 7) % pow2 1); *)
(*   Math.Lemmas.pow2_multiplication_division_lemma_2 b0 7 j; *)
(*   cut (b0j / pow2 7 = b0 / pow2 (7 - j)); *)
(*   Math.Lemmas.pow2_modulo_division_lemma_1 (k / pow2 (8 * i)) (7 - j) 8; *)
(*   cut (b0 / pow2 (7 - j) = ((k / pow2 (8 * i)) / pow2 (7 - j)) % pow2 (8 - (7-j))); admit() *)


(* val lemma_byte_bit: k:nat -> b:byte -> i:nat -> j:nat{j < 8} -> Lemma *)
(*   (requires (let open FStar.Mul in v b = (((k / pow2 (8 * i)) % pow2 8) * pow2 j) % pow2 8)) *)
(*   (ensures (let open FStar.Mul in (v b / pow2 7) % 2 = (k / pow2 (8 * i + j)) % 2)) *)


(* val double_step: *)
(*   (\* k:nat{k < pow2 256} -> *\) *)
(*   (\* i:nat{i < 256} -> *\) *)
(*   q:elem -> *)
(*   nq:proj_point -> *)
(*   nqpq:proj_point -> *)
(*   b:t -> *)
(*   (\* ctr:nat{ctr <= 8 (\\* /\ v b = op_Multiply ((k / pow2 i) % pow2 8) (pow2 (8 - ctr)) *\\)} -> *\) *)
(*   Tot (proj_point * proj_point) *)
(* let double_step (\* k i *\) q nq nqpq b = *)
(*   let nq', nqpq' = small_loop_step (\* k i  *\)q nq nqpq b in *)
(*   let b' = b <<^ 1ul in *)
(*   small_loop_step (\* k (i+1)  *\)q nq' nqpq' b' *)



(* val small_loop: *)
(*   q:elem -> *)
(*   nq:proj_point -> *)
(*   nqpq:proj_point -> *)
(*   b:byte -> *)
(*   ctr:nat{ctr <= 4} -> *)
(*   Tot (proj_point * proj_point) *)
(*       (decreases ctr) *)
(* let rec small_loop q nq nqpq b ctr = *)
(*   if ctr = 0 then (nq, nqpq) *)
(*   else ( *)
(*     let ctr' = ctr - 1 in *)
(*     let nq', nqpq' = double_step q nq nqpq b in *)
(*     let b' = b <<^ 2ul in *)
(*     small_loop q nq' nqpq' b' ctr' *)
(*   ) *)


(* #reset-options "--initial_fuel 9 --max_fuel 9 --z3rlimit 100" *)

(* // TODO *)
(* val lemma_small_loop_unrolled: q:elem -> nq:proj_point -> nqpq:proj_point -> b:byte -> *)
(*   Lemma ( *)
(*     let nq, nqpq = small_loop_step q nq nqpq b in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 1ul) in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 2ul) in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 3ul) in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 4ul)  in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 5ul) in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 6ul) in *)
(*     let b = b <<^ 1ul in *)
(*     let nq, nqpq = small_loop_step q nq nqpq (b <<^ 7ul) in *)
(*     (nq, nqpq) == small_loop q nq nqpq b 4) *)


(* val big_loop: *)
(*   q:elem -> *)
(*   nq:proj_point -> *)
(*   nqpq:proj_point -> *)
(*   k:nat{k < pow2 256} -> *)
(*   i:nat{i <= 32} -> *)
(*   Tot (proj_point * proj_point) *)
(*       (decreases i) *)
(* let rec big_loop q nq nqpq k i = *)
(*   if i = 0 then (nq, nqpq) *)
(*   else ( *)
(*     let i' = i - 1 in *)
(*     let b = k / pow2 (op_Multiply 8 i') % pow2 8 in *)
(*     let nq', nqpq' = small_loop q nq nqpq (UInt8.uint_to_t b) 4 in *)
(*     big_loop q nq' nqpq' k i' *)
(*   ) *)





(* (\* val montgomery_ladder_: *\) *)
(* (\*   init:elem -> *\) *)
(* (\*   x:proj_point -> *\) *)
(* (\*   xp1:proj_point -> *\) *)
(* (\*   k:nat -> *\) *)
(* (\*   ctr:nat -> *\) *)
(* (\*   Tot proj_point *\) *)
(* (\*     (decreases ctr) *\) *)
(* (\* let rec montgomery_ladder_ init x xp1 k ctr = *\) *)
(* (\*   if ctr = 0 then x *\) *)
(* (\*   else ( *\) *)
(* (\*     let ctr' = ctr - 1 in *\) *)
(* (\*     let (x', xp1') = *\) *)
(* (\*       if k / pow2 ctr' % 2 = 1 then ( *\) *)
(* (\*         let nqp2, nqp1 = add_and_double init xp1 x in *\) *)
(* (\*         nqp1, nqp2 *\) *)
(* (\*       ) else add_and_double init x xp1 in *\) *)
(* (\*     montgomery_ladder_ init x' xp1' k ctr' *\) *)
(* (\*   ) *\) *)

