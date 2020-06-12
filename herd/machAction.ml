(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2010-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

(** Implementation of the action interface for machine models *)

module type A = sig
  include Arch_herd.S

  type lannot
  val empty_annot : lannot
  val barrier_sets : (string * (barrier -> bool)) list
  val annot_sets : (string * (lannot -> bool)) list
  val is_atomic : lannot -> bool
  val is_isync : barrier -> bool
  val pp_isync : string
  val pp_annot : lannot -> string
end

module type Config = sig
  val hexa : bool
  val variant : Variant.t -> bool
end

module Make (C:Config) (A : A) : sig

 (* All sorts of accesses, redundunt with symbol hidden in location,
    when symbol is known, which may not be the case *)

  type access_t = A_REG | A_VIR | A_PHY | A_PTE | A_TLB | A_TAG

  type action =
    | Access of Dir.dirn * A.location * A.V.v * A.lannot * MachSize.sz * access_t
    | Barrier of A.barrier
    | Commit of bool (* true = bcc / false = pred *)
(* Atomic modify, (location,value read, value written, annotation *)
    | Amo of A.location * A.V.v * A.V.v * A.lannot * MachSize.sz * access_t
(* NB: Amo used in some arch only (e.g., Arm, RISCV) *)
    | Fault of A.inst_instance_id * A.location * string option
(* Unrolling control *)
    | TooFar
(* Invalidate event, operation (for print and level), address, if any.
   No adresss means complete invalidation at level *)
    | Inv of A.TLBI.op * A.location option

  include Action.S with type action := action and module A = A

  val access_of_location_std : A.location -> access_t

end = struct

  module A = A
  module V = A.V
  open Dir

  let kvm = C.variant Variant.Kvm

  type access_t = A_REG | A_VIR | A_PHY | A_PTE | A_TLB | A_TAG

  let access_of_constant cst =
    let open Constant in
    match cst with
    | Symbolic (Virtual _) -> A_VIR
    | Symbolic (Physical _) -> A_PHY
    | Symbolic (System (PTE,_)) -> A_PTE
    | Symbolic (System (TLB,_)) -> A_TLB
    | Symbolic (System (TAG,_)) -> A_TAG
    | Concrete _|Label _|Tag _ -> assert false

(* precondition: v is a constant symbol *)
  let access_of_value v = match v with
  | V.Var _ -> assert false
  | V.Val cst -> access_of_constant cst

  let access_of_location = function
    | A.Location_reg _ -> A_REG
    | A.Location_global v
    | A.Location_deref (v,_)
      -> access_of_value v

  let access_of_location_std =
    let open Constant in function
      | A.Location_reg _ -> A_REG
      | A.Location_global (V.Val (Symbolic (Virtual _))|V.Var _)
      | A.Location_deref ((V.Val (Symbolic (Virtual _))|V.Var _),_)
        -> A_VIR
      | A.Location_global (V.Val (Symbolic ((System (PTE,_))))) as loc
        ->
          if kvm then A_PTE
          else Warn.fatal "PTE %s while -variant kvm is not active"
              (A.pp_location loc)
      | A.Location_global v
      | A.Location_deref (v,_)
        -> Warn.fatal "access_of_location_std on non-standard symbol '%s'\n" (V.pp_v v)


  type action =
    | Access of dirn * A.location * V.v * A.lannot * MachSize.sz * access_t
    | Barrier of A.barrier
    | Commit of bool
    | Amo of A.location * A.V.v * A.V.v * A.lannot * MachSize.sz * access_t
    | Fault of A.inst_instance_id * A.location * string option
    | TooFar
    | Inv of A.TLBI.op * A.location option


  let mk_init_write l sz v = match v with
  | A.V.Val (Constant.Tag _) ->
      Access(W,l,v,A.empty_annot,sz,A_TAG)
  | _ ->
      Access(W,l,v,A.empty_annot,sz,access_of_location l)

  let pp_action a = match a with
  | Access (d,l,v,an,sz,_) ->
      Printf.sprintf "%s%s%s%s=%s"
        (pp_dirn d)
        (A.pp_location l)
        (A.pp_annot an)
        (if sz = MachSize.Word then "" else MachSize.pp_short sz)
        (V.pp C.hexa v)
  | Barrier b -> A.pp_barrier_short b
  | Commit bcc -> if bcc then "PoD" else "PoD"
  | Amo (loc,v1,v2,an,sz) ->
      Printf.sprintf "RMW(%s)%s%s(%s>%s)"
        (A.pp_annot an)
        (A.pp_location loc) (MachSize.pp_short sz)
        (V.pp C.hexa v1) (V.pp C.hexa v2)
  | Fault (ii,loc,msg) ->
      Printf.sprintf "Fault(proc:%s,poi:%s,loc:%s,type:%s)"
        (A.pp_proc ii.A.proc)
        (A.pp_prog_order_index ii.A.program_order_index)
        (A.pp_location loc)
        (Misc.proj_opt "None" msg)
  | TooFar -> "TooFar"
  | Inv (op,None) ->
      Printf.sprintf "Inv(%s)" (A.TLBI.pp_op op)
  | Inv (op,Some loc) ->
      Printf.sprintf "Inv(%s,%s)" (A.TLBI.pp_op op) (A.pp_location loc)

(* Utility functions to pick out components *)
  let value_of a = match a with
  | Access (_,_ , v,_,_,_)
    -> Some v
  | Barrier _|Commit _|Amo _|Fault _|TooFar|Inv _
    -> None

  let read_of a = match a with
  | Access (R,_,v,_,_,_)
  | Amo (_,v,_,_,_,_)
    -> Some v
  | Access (W, _, _, _,_,_)|Barrier _|Commit _|Fault _
  | TooFar|Inv _
    -> None

  and written_of a = match a with
  | Access (W,_,v,_,_,_)
  | Amo (_,_,v,_,_,_)
    -> Some v
  | Access (R, _, _, _,_,_)|Barrier _|Commit _|Fault _
  | TooFar|Inv _
    -> None

  let location_of a = match a with
  | Access (_, l, _,_,_,_)
  | Amo (l,_,_,_,_,_)
  | Fault (_,l,_)
  | Inv (_,Some l)
    -> Some l
  | Barrier _|Commit _ | TooFar| Inv (_,None) -> None

(* relative to memory *)
  let is_mem_store a = match a with
  | Access (W,A.Location_global _,_,_,_,_)
  | Amo (A.Location_global _,_,_,_,_,_)
    -> true
  | _ -> false

  let is_mem_load a = match a with
  | Access (R,A.Location_global _,_,_,_,_)
  | Amo (A.Location_global _,_,_,_,_,_)
    -> true
  | _ -> false

  let is_additional_mem_load _ = false

  let is_mem a = match a with
  | Access (_,A.Location_global _,_,_,_,_)
  | Amo (A.Location_global _,_,_,_,_,_)
    -> true
  | _ -> false

  let is_additional_mem _ = false

  let is_atomic a = match a with
  | Access (_,_,_,annot,_,_) ->
      is_mem a && A.is_atomic annot
  | _ -> false

  let is_tag = function
    | Access (_,_,_,_,_,A_TAG)
    | Access _ | Barrier _ | Commit _ | Amo _ | Fault _ | TooFar | Inv _ -> false

  let is_inv = function
    | Inv _ -> true
    | Access _|Amo _|Commit _|Barrier _ | Fault _ | TooFar -> false

  let is_at_level lvl = function
    | Inv(op,_) -> A.TLBI.is_at_level lvl op
    | _ -> false

  let is_fault = function
    | Fault _ -> true
    | Access _|Amo _|Commit _|Barrier _ | TooFar | Inv _ -> false

  let to_fault = function
    | Fault (i,A.Location_global x,msg) -> Some ((i.A.proc,i.A.labels),x,msg)
    | Fault _|Access _|Amo _|Commit _|Barrier _ | TooFar | Inv _ -> None


  let get_mem_dir a = match a with
  | Access (d,A.Location_global _,_,_,_,_) -> d
  | _ -> assert false

  let get_mem_size a = match a with
  | Access (_,A.Location_global _,_,_,sz,_) -> sz
  | _ -> assert false

  let is_PTE_access = function 
  | Access (_,_,_,_,_,A_PTE) -> true
  | _ -> false

  let is_PA_val = let open Constant in function
  | (A.V.Val (Symbolic (Physical _))) -> true
  | _ -> false

(* relative to the registers of the given proc *)
  let is_reg_store a (p:int) = match a with
  | Access (W,A.Location_reg (q,_),_,_,_,_) -> p = q
  | _ -> false

  let is_reg_load a (p:int) = match a with
  | Access (R,A.Location_reg (q,_),_,_,_,_) -> p = q
  | _ -> false

  let is_reg a (p:int) = match a with
  | Access (_,A.Location_reg (q,_),_,_,_,_) -> p = q
  | _ -> false

(* Store/Load anywhere *)
  let is_store a = match a with
  | Access (W,_,_,_,_,_)|Amo _ -> true
  | Access (R,_,_,_,_,_)|Barrier _|Commit _|Fault _|TooFar| Inv _ -> false

  let is_load a = match a with
  | Access (R,_,_,_,_,_)|Amo _ -> true
  | Access (W,_,_,_,_,_)|Barrier _|Commit _|Fault _|TooFar|Inv _ -> false

  let compatible_categories loc1 loc2 = match loc1,loc2 with
  | (A.Location_global _,A.Location_global _)
  | (A.Location_reg _,A.Location_reg _)
  | (A.Location_deref _,A.Location_deref _)
      -> true
  | (A.Location_global _,(A.Location_deref _|A.Location_reg _))
  | (A.Location_deref _,(A.Location_global _|A.Location_reg _))
  | (A.Location_reg _,(A.Location_global _|A.Location_deref _))
    -> false

  let compatible_accesses a1 a2 = match a1,a2 with
  | (Access (_,loc1,_,_,_,k1)|Amo (loc1,_,_,_,_,k1)),
    (Access (_,loc2,_,_,_,k2)|Amo (loc2,_,_,_,_,k2))
    ->
      k1 = k2 &&  compatible_categories loc1 loc2
  | _,_ -> assert false

  let is_reg_any a = match a with
  | Access (_,A.Location_reg _,_,_,_,_) -> true
  | _ -> false

  let is_reg_store_any a = match a with
  | Access (W,A.Location_reg _,_,_,_,_) -> true
  | _ -> false

  let is_reg_load_any a = match a with
  | Access (R,A.Location_reg _,_,_,_,_) -> true
  | _ -> false

(* Barriers *)
  let is_barrier a = match a with
  | Barrier _ -> true
  | _ -> false

  let barrier_of a = match a with
  | Barrier b -> Some b
  | _ -> None

  let same_barrier_id _ _ = assert false

(* Commits *)

  let is_commit_bcc a = match a with
  | Commit b -> b
  | _ -> false

  let is_commit_pred a = match a with
  | Commit b -> not b
  | _ -> false

  let is_pod a = match a with
  | Commit _ -> true
  | _ -> false

(* Unroll control *)
  let toofar = TooFar

  let is_toofar = function
    | TooFar -> true
    | _ -> false

(* Architecture-specific sets *)

  let arch_sets =
    let bsets =
      List.map
        (fun (tag,p) ->
          let p act = match act with
          | Barrier b -> p b
          | _ -> false
          in tag,p) A.barrier_sets
    and asets =
      List.map
        (fun (tag,p) ->
          let p act = match act with
          | Access(_,_,_,annot,_,_)|Amo (_,_,_,annot,_,_) -> p annot
          | _ -> false
          in tag,p) A.annot_sets
    and lsets =
      List.map
        (fun lvl -> A.pp_level lvl,is_at_level lvl)
        A.levels
    in
    ("T",is_tag)::("FAULT",is_fault)::("TLBI",is_inv)::
    bsets @ asets @ lsets

  let arch_rels =
    if kvm then
      let open Constant in
      let ok_sym a1 a2 = match a1,a2 with
      | ((Virtual ((s1,_),_)|Physical (s1,_)|System (PTE,s1)),System (TLB,s2))
      | (System (TLB,s2),(Virtual ((s1,_),_)|Physical (s1,_)|System (PTE,s1)))
          -> Misc.string_eq s1 s2
      | _,_ -> false in

      let ok_loc loc1 loc2 = match loc1,loc2 with
      | A.Location_global (A.V.Val (Symbolic a1)),
        A.Location_global (A.V.Val (Symbolic a2))
          -> ok_sym a1 a2
      | _,_ -> false in

      let ok_act act1 act2 = match act1,act2 with
      | (act,Inv (_,None))|(Inv (_, None),act)
        ->
          is_mem act &&
          begin match location_of act with
          | Some (A.Location_global _) ->  true
          | Some _|None -> false
          end
      | (e,Inv (_,Some loc1))|(Inv (_, Some loc1),e)
        ->
          is_mem e &&
          begin match location_of e with
          | Some loc2 -> ok_loc loc1 loc2
          | None -> false
          end
      | _ -> false in
      ["inv-loc",ok_act]
    else []

  let is_isync act = match act with
  | Barrier b -> A.is_isync b
  | _ -> false

  let pp_isync = A.pp_isync

(* Equations *)
  let add_v_undet v vs =
    if V.is_var_determined v then vs
    else  V.ValueSet.add v vs

  let undetermined_vars_in_action a =
    match a with
    | Access (_,l,v,_,_,_) ->
        let undet_loc = match A.undetermined_vars_in_loc l with
        | None -> V.ValueSet.empty
        | Some v -> V.ValueSet.singleton v in
        add_v_undet v undet_loc
    | Amo (loc,v1,v2,_,_,_) ->
        let undet = match A.undetermined_vars_in_loc loc with
        | None -> V.ValueSet.empty
        | Some v -> V.ValueSet.singleton v in
        add_v_undet v1 (add_v_undet v2 undet)
   | Barrier _|Commit _|Fault _|TooFar|Inv _ -> V.ValueSet.empty

  let simplify_vars_in_action soln a =
    match a with
    | Access (d,l,v,an,sz,t) ->
        let l = A.simplify_vars_in_loc soln l in
        let v = V.simplify_var soln v in
        Access (d,l,v,an,sz,t)
    | Amo (loc,v1,v2,an,sz,t) ->
        let loc =  A.simplify_vars_in_loc soln loc in
        let v1 = V.simplify_var soln v1 in
        let v2 = V.simplify_var soln v2 in
        Amo (loc,v1,v2,an,sz,t)
    | Fault (ii,loc,msg) ->
        let loc = A.simplify_vars_in_loc soln loc in
        Fault(ii,loc,msg)
    | Inv (op,oloc) ->
        let oloc = Misc.app_opt (A.simplify_vars_in_loc soln) oloc in
        Inv (op,oloc)
    | Barrier _ | Commit _|TooFar -> a

  let annot_in_list _str _ac = false

end
