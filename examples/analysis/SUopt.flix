
//// Inputs
//// =========
  rel AddrOf(variable: Str, object: Str)
  rel Copy(to: Str, from: Str)
  rel Store(label: Str, to: Str, from: Str)
  rel Load(label: Str, to: Str, from: Str)
  rel CFG(label: Str, to: Str)
  rel Multi(object: Str)
  rel Phi(label: Str)
  rel Clear(label: Str)
  rel FIStore(to: Str, from: Str, unknown: Str)
  rel FILoad(to: Str, from: Str, unknown: Str)

//// Outputs
//// =========
  rel Pt(variable: Str, target: Str)

//// Indexes
//// =========
  index AddrOf({variable, object})
  index Copy({to, from}, {from});
  index Store({label, to, from}, {to}, {from});
  index Load({label, to, from}, {label}, {from});
  index CFG({label, to}, {label}, {to});
  index FIStore({to}, {from});
  index FILoad({from});

  index Pt({variable, target}, {variable});
  index PtH({object, target}, {object});

//// Other types
//// =========
  enum SULattice {
    case Top, // kill nothing
    case Single(Str),
    case Bottom // kill everything
  }

  def leq(e1: SULattice, e2: SULattice): Bool = match (e1, e2) with {
    case (SULattice.Bottom, _) => true;
    case (_, SULattice.Top) => true;
    case (SULattice.Single(s1), SULattice.Single(s2)) => s1 == s2;
    case _ => false;
  }
  def lub(e1: SULattice, e2: SULattice): SULattice = match (e1, e2) with {
    case (SULattice.Bottom, e2) => e2;
    case (e1, SULattice.Bottom) => e1;
    case (SULattice.Single(s1), SULattice.Single(s2)) => if (s1 == s2) SULattice.Single(s1) else SULattice.Top;
    case _ => SULattice.Top;
  }
  def glb(e1: SULattice, e2: SULattice): SULattice = match (e1, e2) with {
    case (SULattice.Top, e2) => e2;
    case (e1, SULattice.Top) => e1;
    case (SULattice.Single(s1), SULattice.Single(s2)) => if (s1 == s2) SULattice.Single(s1) else SULattice.Bottom;
    case _ => SULattice.Bottom;
  }
  let SULattice<> = (SULattice.Bottom, SULattice.Top, leq, lub, glb);

  lat SU(location: Str, object: Str, target: SULattice)

  rel PtH(object: Str, target: Str)
  lat Kill(location: Str, kill: SULattice)

//// Rules
//// =========
//
//// AddrOf
//// ---------
Pt(p,a) :- AddrOf(p,a).
//
//// Copy
//// ---------
Pt(p,a) :- Copy(p,q), Pt(q,a).
//
//// Store
//// ---------
def f(x: Str): SULattice = SULattice.Single(x)
SU(l,a,f(b)) :- Store(l,p,q), Pt(p,a), Pt(q,b).
//
PtH(a,b) :- Store(l,p,q), Pt(p,a), Pt(q,b).
PtH(a,b) :- FIStore(p,q,_), Pt(p,a), Pt(q,b).
//
//// Load
//// ---------
Pt(p,b) :- Load(l,p,q), Pt(q,a), filter(t, b), PtH(a,b), SU(l,a,t).
Pt(p,b) :- FILoad(p,q,_), Pt(q,a), PtH(a,b).
//
//// CFlow
//// ---------
//SU(l2,a,t) :- CFG(l1,l2), SU(l1,a,t).
//
//// Preserve
//// ---------
////su-after(l,a,t) :- su-before(l,a,t), NOT kill(l,a).
def killNot(a: Str, e: SULattice): Bool = match e with {
  case SULattice.Bottom => false
  case SULattice.Single(s) => a != s
  case SULattice.Top => true
}
SU(l2,a,t) :- CFG(l1, l2), SU(l1,a,t), Multi(a).
SU(l2,a,t) :- CFG(l1, l2), SU(l1,a,t), killNot(a, k), Kill(l2,k).
//SU(l2,a,t) :- CFG(l1, l2), SU(l1,a,t), Phi(l2).
//
//// PtSu
//// ---------
def filter(e: SULattice, p: Str): Bool = match e with {
  case SULattice.Bottom => false
  case SULattice.Single(s) => p == s
  case SULattice.Top => true
}
SU(l,a,f(b)) :- Clear(l), PtH(a,b).

//// Kill
//// ---------
def top(e: Int): SULattice = SULattice.Top;
Kill(l,f(b)) :- Store(l,p,q), Pt(p,b).
Kill(l, top(42)) :- Phi(l,_,_).

// uncomment to introduce an error delta debugging
//def isTop(e: SULattice): Bool = match e with {
//   case SULattice.Bottom => false
//   case SULattice.Single(s) => false
//   case SULattice.Top => true // (1 / 0) == 0
//}

//false :- isTop(x), SU("431", "212 hbMakeCodeLengths:freq_addr<mem>", x).