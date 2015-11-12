package ca.uwaterloo.flix.runtime

import ca.uwaterloo.flix.language.ast.TypedAst.{Expression, Literal, Pattern, Type, Term, Root}
import ca.uwaterloo.flix.language.ast.{BinaryOperator, UnaryOperator}

import scala.annotation.tailrec
import scala.collection.mutable

// TODO: Consider an EvaluationContext
object Interpreter {

  type Env = mutable.Map[String, Value]

  // TODO: Use this exception:

  /**
   * An exception thrown to indicate an internal runtime error.
   *
   * This exception should never be thrown if the compiler and runtime is implemented correctly.
   *
   * @param message the error message.
   */
  case class InternalRuntimeError(message: String) extends RuntimeException(message)

  /*
   * Evaluates an `Expression`. Based on the type of `expr`, call either the
   * specialized `evalInt` or `evalBool`, or the general `evalGeneral`
   * evaluator.
   *
   * Assumes all input has been type-checked.
   */
  def eval(expr: Expression, root: Root, env: Env = mutable.Map.empty): Value = expr.tpe match {
    case Type.Int => Value.mkInt(evalInt(expr, root, env))
    case Type.Bool => if (evalBool(expr, root, env)) Value.True else Value.False
    case Type.Str => evalGeneral(expr, root, env)
    case Type.Var(_) | Type.Unit | Type.Tag(_, _, _) | Type.Enum(_) | Type.Tuple(_) |
         Type.Set(_) | Type.Lambda(_, _) | Type.Predicate(_) | Type.Native(_) =>
      evalGeneral(expr, root, env)
  }

  /*
   * Evaluates expressions of type `Type.Int`, returning an unwrapped
   * `scala.Int`. Performs casting as necessary.
   *
   * Subexpressions are evaluated by calling specialized eval whenever
   * possible. For example, subexpressions of int binary expressions must
   * themselves be int expressions, so we can call `evalInt`. On the other
   * hand, the condition of an IfThenElse expression must have type bool, so we
   * call `evalBool`. And if the expression cannot have int or bool type (for
   * example, the `exp` of Apply(exp, args, _, _), we directly call
   * `evalGeneral`.
   */
  def evalInt(expr: Expression, root: Root, env: Env = mutable.Map.empty): Int = {
    def evalUnary(op: UnaryOperator, e: Expression): Int = op match {
      case UnaryOperator.UnaryPlus => +evalInt(e, root, env)
      case UnaryOperator.UnaryMinus => -evalInt(e, root, env)
      case UnaryOperator.Set.Size => eval(e, root, env).toSet.size
      case UnaryOperator.Not | UnaryOperator.Set.IsEmpty | UnaryOperator.Set.NonEmpty | UnaryOperator.Set.Singleton =>
        throw new InternalRuntimeError(s"Unary expression $expr has type ${expr.tpe} instead of Type.Int.")
    }

    // TODO: Document semantics of modulo on negative operands
    def evalBinary(op: BinaryOperator, e1: Expression, e2: Expression): Int = op match {
      case BinaryOperator.Plus => evalInt(e1, root, env) + evalInt(e2, root, env)
      case BinaryOperator.Minus => evalInt(e1, root, env) - evalInt(e2, root, env)
      case BinaryOperator.Times => evalInt(e1, root, env) * evalInt(e2, root, env)
      case BinaryOperator.Divide => evalInt(e1, root, env) / evalInt(e2, root, env)
      case BinaryOperator.Modulo => evalInt(e1, root, env) % evalInt(e2, root, env)
      case BinaryOperator.Less | BinaryOperator.LessEqual | BinaryOperator.Greater | BinaryOperator.GreaterEqual |
           BinaryOperator.Equal | BinaryOperator.NotEqual | BinaryOperator.And | BinaryOperator.Or |
           BinaryOperator.Set.Member | BinaryOperator.Set.SubsetOf | BinaryOperator.Set.ProperSubsetOf |
           BinaryOperator.Set.Insert | BinaryOperator.Set.Remove | BinaryOperator.Set.Union |
           BinaryOperator.Set.Intersection | BinaryOperator.Set.Difference =>
        throw new InternalRuntimeError(s"Binary expression $expr has type ${expr.tpe} instead of Type.Int.")
    }

    expr match {
      case Expression.Lit(literal, _, _) => evalLit(literal).toInt
      case Expression.Var(ident, _, loc) => env(ident.name).toInt
      case Expression.Ref(name, _, _) => evalInt(root.constants(name).exp, root, env)
      case Expression.Apply(exp, args, _, _) =>
        val evalArgs = args.map(x => eval(x, root, env))
        evalCall(exp, evalArgs, root, env).toInt
      case Expression.Unary(op, exp, _, _) => evalUnary(op, exp)
      case Expression.Binary(op, exp1, exp2, _, _) => evalBinary(op, exp1, exp2)
      case Expression.IfThenElse(exp1, exp2, exp3, tpe, _) =>
        val cond = evalBool(exp1, root, env)
        if (cond) evalInt(exp2, root, env) else evalInt(exp3, root, env)
      case Expression.Let(ident, exp1, exp2, _, _) =>
        // TODO: Right now Let only supports a single binding. Does it make sense to allow a list of bindings?
        val newEnv = env + (ident.name -> eval(exp1, root, env))
        evalInt(exp2, root, newEnv)
      case Expression.Match(exp, rules, _, _) =>
        val value = eval(exp, root, env)
        val result = matchRule(rules, value)
        if (result != null) evalInt(result._1, root, env ++ result._2)
        else throw new RuntimeException(s"Unmatched value $value.")
      case Expression.NativeField(field, _, _) =>
        field.get().asInstanceOf[java.lang.Integer].intValue()
      case Expression.Lambda(_, _, _, _) | Expression.Tag(_, _, _, _, _) | Expression.Tuple(_, _, _) |
           Expression.Set(_, _, _) | Expression.NativeMethod(_, _, _) =>
        throw new InternalRuntimeError(s"Expression $expr has type ${expr.tpe} instead of Type.Int.")
      case Expression.Error(tpe, loc) => throw new RuntimeException(s"Error at ${loc.format}.")
    }
  }

  /*
   * Evaluates expressions of type `Type.Bool`, returning an unwrapped
   * `scala.Boolean`. Performs casting as necessary.
   *
   * Subexpressions are evaluated by calling specialized eval whenever
   * possible.
   */
  def evalBool(expr: Expression, root: Root, env: Env = mutable.Map.empty): Boolean = {
    def evalUnary(op: UnaryOperator, e: Expression): Boolean = op match {
      case UnaryOperator.Not => !evalBool(e, root, env)
      case UnaryOperator.Set.IsEmpty => eval(e, root, env).toSet.isEmpty
      case UnaryOperator.Set.NonEmpty => eval(e, root, env).toSet.nonEmpty
      case UnaryOperator.Set.Singleton => eval(e, root, env).toSet.size == 1
      case UnaryOperator.UnaryPlus | UnaryOperator.UnaryMinus | UnaryOperator.Set.Size =>
        throw new InternalRuntimeError(s"Unary expression $expr has type ${expr.tpe} instead of Type.Bool.")
    }

    def evalBinary(op: BinaryOperator, e1: Expression, e2: Expression): Boolean = op match {
      case BinaryOperator.Less => evalInt(e1, root, env) < evalInt(e2, root, env)
      case BinaryOperator.LessEqual => evalInt(e1, root, env) <= evalInt(e2, root, env)
      case BinaryOperator.Greater => evalInt(e1, root, env) > evalInt(e2, root, env)
      case BinaryOperator.GreaterEqual => evalInt(e1, root, env) >= evalInt(e2, root, env)
      case BinaryOperator.Equal => eval(e1, root, env) == eval(e2, root, env)
      case BinaryOperator.NotEqual => eval(e1, root, env) != eval(e2, root, env)
      case BinaryOperator.And => evalBool(e1, root, env) && evalBool(e2, root, env)
      case BinaryOperator.Or => evalBool(e1, root, env) || evalBool(e2, root, env)
      case BinaryOperator.Set.Member => eval(e2, root, env).toSet contains eval(e1, root, env)
      case BinaryOperator.Set.SubsetOf => eval(e1, root, env).toSet subsetOf eval(e2, root, env).toSet
      case BinaryOperator.Set.ProperSubsetOf =>
        val s1 = eval(e1, root, env).toSet
        val s2 = eval(e2, root, env).toSet
        s1.subsetOf(s2) && s1.size < s2.size
      case BinaryOperator.Plus | BinaryOperator.Minus | BinaryOperator.Times | BinaryOperator.Divide |
           BinaryOperator.Modulo | BinaryOperator.Set.Insert | BinaryOperator.Set.Remove | BinaryOperator.Set.Union |
           BinaryOperator.Set.Intersection | BinaryOperator.Set.Difference =>
        throw new InternalRuntimeError(s"Binary expression $expr has type ${expr.tpe} instead of Type.Bool.")
    }

    expr match {
      case Expression.Lit(literal, _, _) => evalLit(literal).toBool
      case Expression.Var(ident, _, loc) => env(ident.name).toBool
      case Expression.Ref(name, _, _) => evalBool(root.constants(name).exp, root, env)
      case Expression.Apply(exp, args, _, _) =>
        val evalArgs = args.map(x => eval(x, root, env))
        evalCall(exp, evalArgs, root, env).toBool
      case Expression.Unary(op, exp, _, _) => evalUnary(op, exp)
      case Expression.Binary(op, exp1, exp2, _, _) => evalBinary(op, exp1, exp2)
      case Expression.IfThenElse(exp1, exp2, exp3, tpe, _) =>
        val cond = evalBool(exp1, root, env)
        if (cond) evalBool(exp2, root, env) else evalBool(exp3, root, env)
      case Expression.Let(ident, exp1, exp2, _, _) =>
        // TODO: Right now Let only supports a single binding. Does it make sense to allow a list of bindings?
        val newEnv = env + (ident.name -> eval(exp1, root, env))
        evalBool(exp2, root, newEnv)
      case Expression.Match(exp, rules, _, _) =>
        val value = eval(exp, root, env)
        val result = matchRule(rules, value)
        if (result != null) evalBool(result._1, root, env ++ result._2)
        else throw new RuntimeException(s"Unmatched value $value.")
      case Expression.NativeField(field, _, _) =>
        field.get().asInstanceOf[java.lang.Boolean].booleanValue()
      case Expression.Lambda(_, _, _, _) | Expression.Tag(_, _, _, _, _) | Expression.Tuple(_, _, _) |
           Expression.Set(_, _, _) | Expression.NativeMethod(_, _, _) =>
        throw new InternalRuntimeError(s"Expression $expr has type ${expr.tpe} instead of Type.Bool.")
      case Expression.Error(tpe, loc) => throw new RuntimeException(s"Error at ${loc.format}.")
    }
  }

  /*
   * A general evaluator of `Expression`s.
   *
   * Subexpressions are always evaluated by calling `eval`, which will call the
   * specialized eval whenever possible.
   */
  def evalGeneral(expr: Expression, root: Root, env: Env = mutable.Map.empty): Value = {
    def evalUnary(op: UnaryOperator, v: Value): Value = op match {
      case UnaryOperator.Not => if (v.toBool) Value.False else Value.True
      case UnaryOperator.UnaryPlus => Value.mkInt(+v.toInt)
      case UnaryOperator.UnaryMinus => Value.mkInt(-v.toInt)
      case UnaryOperator.Set.IsEmpty => if (v.toSet.isEmpty) Value.True else Value.False
      case UnaryOperator.Set.NonEmpty => if (v.toSet.nonEmpty) Value.True else Value.False
      case UnaryOperator.Set.Singleton => if (v.toSet.size == 1) Value.True else Value.False
      case UnaryOperator.Set.Size => Value.mkInt(v.toSet.size)
    }

    def evalBinary(op: BinaryOperator, v1: Value, v2: Value): Value = op match {
      case BinaryOperator.Plus => Value.mkInt(v1.toInt + v2.toInt)
      case BinaryOperator.Minus => Value.mkInt(v1.toInt - v2.toInt)
      case BinaryOperator.Times => Value.mkInt(v1.toInt * v2.toInt)
      case BinaryOperator.Divide => Value.mkInt(v1.toInt / v2.toInt)
      case BinaryOperator.Modulo => Value.mkInt(v1.toInt % v2.toInt)
      case BinaryOperator.Less => if (v1.toInt < v2.toInt) Value.True else Value.False
      case BinaryOperator.LessEqual => if (v1.toInt <= v2.toInt) Value.True else Value.False
      case BinaryOperator.Greater => if (v1.toInt > v2.toInt) Value.True else Value.False
      case BinaryOperator.GreaterEqual => if (v1.toInt >= v2.toInt) Value.True else Value.False
      case BinaryOperator.Equal => if (v1 == v2) Value.True else Value.False
      case BinaryOperator.NotEqual => if (v1 != v2) Value.True else Value.False
      case BinaryOperator.And => if (v1.toBool && v2.toBool) Value.True else Value.False
      case BinaryOperator.Or => if (v1.toBool || v2.toBool) Value.True else Value.False
      case BinaryOperator.Set.Member => if (v2.toSet.contains(v1)) Value.True else Value.False
      case BinaryOperator.Set.SubsetOf => if (v1.toSet.subsetOf(v2.toSet)) Value.True else Value.False
      case BinaryOperator.Set.ProperSubsetOf =>
        if (v1.toSet.subsetOf(v2.toSet) && v1.toSet.size < v2.toSet.size) Value.True else Value.False
      case BinaryOperator.Set.Insert => Value.Set(v1.toSet + v2)
      case BinaryOperator.Set.Remove => Value.Set(v1.toSet - v2)
      case BinaryOperator.Set.Union => Value.Set(v1.toSet | v2.toSet)
      case BinaryOperator.Set.Intersection => Value.Set(v1.toSet & v2.toSet)
      case BinaryOperator.Set.Difference => Value.Set(v1.toSet &~ v2.toSet)
    }

    expr match {
      case Expression.Lit(literal, _, _) => evalLit(literal)
      case Expression.Var(ident, _, loc) => env(ident.name)
      case Expression.Ref(name, _, _) => eval(root.constants(name).exp, root, env)
      case Expression.Lambda(formals, body, _, _) => Value.Closure(formals, body, env)
      case Expression.Apply(exp, args, _, _) =>
        val evalArgs = args.map(x => eval(x, root, env))
        evalCall(exp, evalArgs, root, env)
      case Expression.Unary(op, exp, _, _) => evalUnary(op, eval(exp, root, env))
      case Expression.Binary(op, exp1, exp2, _, _) => evalBinary(op, eval(exp1, root, env), eval(exp2, root, env))
      case Expression.IfThenElse(exp1, exp2, exp3, tpe, _) =>
        val cond = evalBool(exp1, root, env)
        if (cond) eval(exp2, root, env) else eval(exp3, root, env)
      case Expression.Let(ident, exp1, exp2, _, _) =>
        // TODO: Right now Let only supports a single binding. Does it make sense to allow a list of bindings?
        val newEnv = env + (ident.name -> eval(exp1, root, env))
        eval(exp2, root, newEnv)
      case Expression.Match(exp, rules, _, _) =>
        val value = eval(exp, root, env)
        val result = matchRule(rules, value)
        if (result != null) eval(result._1, root, env ++ result._2)
        else throw new RuntimeException(s"Unmatched value $value.")
      case Expression.NativeField(field, tpe, _) => Value.java2flix(field.get(), tpe)
      case Expression.NativeMethod(method, _, _) => Value.NativeMethod(method)
      case Expression.Tag(name, ident, exp, _, _) => Value.mkTag(name, ident.name, eval(exp, root, env))
      case Expression.Tuple(elms, _, _) => Value.Tuple(elms.map(e => eval(e, root, env)))
      case Expression.Set(elms, _, _) => Value.Set(elms.map(e => eval(e, root, env)).toSet)
      case Expression.Error(tpe, loc) => throw new RuntimeException(s"Error at ${loc.format}.")
    }
  }

  def evalLit(lit: Literal): Value = lit match {
    case Literal.Unit(_) => Value.Unit
    case Literal.Bool(b, _) => if (b) Value.True else Value.False
    case Literal.Int(i, _) => Value.mkInt(i)
    case Literal.Str(s, _) => Value.mkStr(s)
    case Literal.Tag(name, ident, innerLit, _, _) => Value.mkTag(name, ident.name, evalLit(innerLit))
    case Literal.Tuple(elms, _, _) => Value.Tuple(elms.map(evalLit))
    case Literal.Set(elms, _, _) => Value.Set(elms.map(evalLit).toSet)
  }

  // Returns `null` if there is no match.
  @tailrec private def matchRule(rules: List[(Pattern, Expression)], value: Value): (Expression, Env) = rules match {
    case (pattern, exp) :: rest =>
      val env = unify(pattern, value)
      if (env != null) (exp, env)
      else matchRule(rest, value)
    case Nil => null
  }

  // Returns `null` if unification fails.
  private def unify(pattern: Pattern, value: Value): Env = (pattern, value) match {
    case (Pattern.Wildcard(_, _), _) => mutable.Map.empty
    case (Pattern.Var(ident, _, _), _) => mutable.Map(ident.name -> value)
    case (Pattern.Lit(lit, _, _), _) if evalLit(lit) == value => mutable.Map.empty
    case (Pattern.Tag(name1, ident1, innerPat, _, _), v) => v match {
      case v: Value.Tag if name1 == v.enum && ident1.name == v.tag => unify(innerPat, v.value)
      case _ => null
    }
    case (Pattern.Tuple(pats, _, _), Value.Tuple(vals)) =>
      val result: Env = mutable.Map.empty
      val length = pats.length
      var i = 0
      while (i < length) {
        val env = unify(pats(i), vals(i))
        if (env == null) return null
        result ++= env
        i = i + 1
      }
      result
    case _ => null
  }

  // TODO: Need to come up with some more clean interfaces
  // TODO: Everything below here is really bad and should just be replaced at will.

  /**
   * Evaluates the given head term `t` under the given environment `env0`
   */
  def evalHeadTerm(t: Term.Head, root: Root, env: mutable.Map[String, Value]): Value = t match {
    case Term.Head.Var(x, _, _) => env(x.name)
    case Term.Head.Lit(lit, _, _) => evalLit(lit)
    case Term.Head.Apply(name, terms, _, _) =>
      val function = root.constants(name).exp
      val evalArgs = terms.map(t => evalHeadTerm(t, root, env))
      evalCall(function, evalArgs, root, env)
    case Term.Head.NativeField(field, tpe, _) => Value.java2flix(field.get(), tpe)
  }

  def evalBodyTerm(t: Term.Body, env: Env): Value = t match {
    case Term.Body.Wildcard(_, _) => ???
    case Term.Body.Var(x, _, _) => env(x.name)
    case Term.Body.Lit(lit, _, _) => evalLit(lit)
  }

  def evalCall(function: Expression, args: List[Value], root: Root, env: Env = mutable.Map.empty): Value =
    (evalGeneral(function, root, env): @unchecked) match {
      case Value.Closure(formals, body, closureEnv) =>
        val newEnv = closureEnv ++ formals.map(_.ident.name).zip(args).toMap
        eval(body, root, newEnv)
      case Value.NativeMethod(method) =>
        val nativeArgs = args.map(_.toJava)
        val tpe = function.tpe.asInstanceOf[Type.Lambda].retTpe
        Value.java2flix(method.invoke(null, nativeArgs: _*), tpe)
    }

  def eval2(function: Expression, arg1: Value, arg2: Value, root: Root): Value =
    (evalGeneral(function, root): @unchecked) match {
      case Value.Closure(formals, body, closureEnv) =>
        val newEnv = closureEnv.clone()
        newEnv.update(formals(0).ident.name, arg1)
        newEnv.update(formals(1).ident.name, arg2)
        eval(body, root, newEnv)
      case Value.NativeMethod(method) =>
        val tpe = function.tpe.asInstanceOf[Type.Lambda].retTpe
        Value.java2flix(method.invoke(null, arg1.toJava, arg2.toJava), tpe)
    }
}
