Hello world should work:

  $ aslref hello_world.asl
  Hello, world!

ASL Semantics Reference:
  $ aslref SemanticsRule.ELocalVar.asl
  $ aslref SemanticsRule.EGlobalVar.asl
//  $ aslref SemanticsRule.EGlobalVarError.asl
  $ aslref SemanticsRule.EUndefIdent.asl
  File SemanticsRule.EUndefIdent.asl, line 5, characters 9 to 10:
  ASL Error: Undefined identifier: 'y'
  [1]
//  $ aslref SemanticsRule.EBinopPlusPrint.asl
  $ aslref SemanticsRule.EBinopPlusAssert.asl
  $ aslref SemanticsRule.EBinopDIVBackendDefinedError.asl
  File SemanticsRule.EBinopDIVBackendDefinedError.asl, line 4,
    characters 10 to 17:
  ASL Typing error: Illegal application of operator DIV on types integer {3}
    and integer {0}
  [1]
  $ aslref --no-type-check SemanticsRule.EBinopDIVBackendDefinedError.asl
  ASL Execution error: Illegal application of operator DIV for values 3 and 0.
  [1]
  $ aslref SemanticsRule.EUnopAssert.asl
  $ aslref SemanticsRule.ECondFALSE.asl
  $ aslref SemanticsRule.ECondUNKNOWN3.asl
  $ aslref SemanticsRule.ECondUNKNOWN42.asl
  File SemanticsRule.ECondUNKNOWN42.asl, line 10, characters 9 to 14:
  ASL Execution error: Assertion failed: (x == 42)
  [1]
  $ aslref SemanticsRule.ESlice.asl
  $ aslref SemanticsRule.ECall.asl
  $ aslref SemanticsRule.EGetArray.asl
  $ aslref SemanticsRule.EGetArrayTooSmall.asl
  File SemanticsRule.EGetArrayTooSmall.asl, line 8, characters 2 to 10:
  ASL Typing error: a subtype of integer {3} was expected,
    provided integer {0..(3 - 1)}.
  [1]
  $ aslref SemanticsRule.ERecord.asl
  $ aslref SemanticsRule.EConcat.asl
  $ aslref SemanticsRule.ETuple.asl
  $ aslref SemanticsRule.EUnknownInteger0.asl
  $ aslref SemanticsRule.EUnknownInteger3.asl
  File SemanticsRule.EUnknownInteger3.asl, line 5, characters 9 to 13:
  ASL Execution error: Assertion failed: (x == 3)
  [1]
  $ aslref SemanticsRule.EUnknownIntegerRange3-42-3.asl
  $ aslref SemanticsRule.EUnknownIntegerRange3-42-42.asl
  File SemanticsRule.EUnknownIntegerRange3-42-42.asl, line 5,
    characters 9 to 14:
  ASL Execution error: Assertion failed: (x == 42)
  [1]
  $ aslref SemanticsRule.EPatternFALSE.asl
  $ aslref SemanticsRule.EPatternTRUE.asl
  $ aslref SemanticsRule.LELocalVar.asl
  $ aslref SemanticsRule.LEGlobalVar.asl
  File /Users/jadalg01/herdtools7/asllib/libdir/stdlib.asl, line 250,
    character 0 to line 253, character 3:
  ASL Typing error: cannot declare already declared element "x".
  [1]
  $ aslref SemanticsRule.LESetArray.asl
  $ aslref SemanticsRule.SReturnNone.asl
  $ aslref SemanticsRule.SCond.asl
  $ aslref SemanticsRule.SCase.asl
  $ aslref SemanticsRule.SWhile.asl
  $ aslref SemanticsRule.SRepeat.asl
  $ aslref SemanticsRule.SFor.asl
  $ aslref SemanticsRule.SThrowNone.asl
  $ aslref SemanticsRule.SThrowSomeTyped.asl
  $ aslref SemanticsRule.SThrowSTry.asl
  aslref cannot find file "SemanticsRule.SThrowSTry.asl"
  [1]
  $ aslref SemanticsRule.Loop.asl
  $ aslref SemanticsRule.For.asl
  $ aslref SemanticsRule.Catch.asl
  $ aslref SemanticsRule.CatchNamed.asl
  $ aslref SemanticsRule.CatchOtherwise.asl
  $ aslref SemanticsRule.CatchNone.asl
  File SemanticsRule.CatchNone.asl, line 15, characters 8 to 24:
  ASL Error: Cannot parse.
  [1]
  $ aslref SemanticsRule.FUndefIdent.asl
  File SemanticsRule.FUndefIdent.asl, line 4, characters 5 to 12:
  ASL Error: Undefined identifier: 'foo'
  [1]
  $ aslref SemanticsRule.FCall.asl
  $ aslref SemanticsRule.PAll.asl
  $ aslref SemanticsRule.PAnyTRUE.asl
  $ aslref SemanticsRule.PAnyFALSE.asl
  $ aslref SemanticsRule.PGeqTRUE.asl
  $ aslref SemanticsRule.PGeqFALSE.asl
  $ aslref SemanticsRule.PLeqTRUE.asl
  $ aslref SemanticsRule.PLeqFALSE.asl
  $ aslref SemanticsRule.PNotTRUE.asl
  $ aslref SemanticsRule.PNotFALSE.asl
  $ aslref SemanticsRule.PRangeTRUE.asl
  $ aslref SemanticsRule.PRangeFALSE.asl
  $ aslref SemanticsRule.PSingleTRUE.asl
  $ aslref SemanticsRule.PSingleFALSE.asl
  $ aslref SemanticsRule.PMaskTRUE.asl
  $ aslref SemanticsRule.PMaskFALSE.asl
  $ aslref SemanticsRule.PTupleTRUE.asl
  $ aslref SemanticsRule.PTupleFALSE.asl









