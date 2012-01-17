#.(progn
    (require :asdf)
    (require :vector)
#+nil    (require :simple-gl)
    (require :simplex-anneal))

;; for i in `cat raytrace.lisp|grep defun|grep -v '^;'|cut -d " " -f2`;
;; do echo \#:$i ;done


(defpackage :raytrace
  (:use :cl :vector :simplex-anneal)
  (:export #:quadratic-roots
	   #:ray-sphere-intersection-length
	   #:direction
	   #:ray-spheres-intersection
	   #:sphere
	   #:center
	   #:radius
	   #:make-sphere
	   #:sphere-center
	   #:sphere-radius
	   #:ray-lost
	   #:no-solution))

(in-package :raytrace)

(declaim (optimize (speed 2) (safety 3) (debug 3)))


(define-condition one-solution () ())

(define-condition ray-lost () ())

(define-condition no-solution () ())

(defun quadratic-roots (a b c)
  (declare (double-float a b c)
	   (values double-float double-float &optional))
  "Find the two roots of ax^2+bx+c=0 and return them as multiple
  values. If no root exists the signal NO-SOLUTION is emitted."
  (declare (double-float a b c)
	   (values double-float &optional double-float))
  ;; see numerical recipes sec 5.6, p. 251 on how to avoid roundoff
  ;; error
  (let ((det2 (- (* b b) (* 4 a c))))
    (unless (<= 0d0 det2)
      (error 'no-solution))
    (let* ((pdet2 det2)
	   (q (* .5d0 (+ b (* (signum b) (sqrt pdet2)))))
	   (aa (abs a))
	   (aq (abs q)))
      (declare ((double-float 0d0) pdet2))
      (cond ((and (< aq 1d-12) (< aa 1d-12)) (error 'no-solution))
	    ((or (< aq 1d-12) (< aa 1d-12)) (error 'one-solution))
	    (t (values (/ q a) (/ c q)))))))

#+nil ;; two solution
(quadratic-roots 1d0 2d0 -3d0)
#+nil ;; one solution
(quadratic-roots 0d0 1d0 0d0)
#+nil ;; no solution
(quadratic-roots 0d0 -0d0 1d0)

(defclass sphere ()
  ((center :accessor center :initarg :center :initform (v) :type vec)
   (radius :accessor radius :initarg :radius :initform 1d0 :type double-float)))


(defmethod print-object ((sphere sphere) stream)
  (with-slots (center radius) sphere
    (format stream "#<sphere radius: ~4f center: <~4f ~4f ~4f>>" 
	    radius (vec-x center) (vec-y center) (vec-z center))))
    (unless (< 0d0 det2)
      (signal 'no-solution))
    (let* ((q (* .5d0 (+ b (* (signum b) (sqrt det2)))))
	   (aa (abs a))
	   (aq (abs q)))
      (cond ((and (< aq 1d-12) (< aa 1d-12)) (signal 'no-solution))
	    ((< aq 1d-12) (/ q a))
	    ((< aa 1d-12) (/ c q))
	    (t (values (/ q a) (/ c q)))))))

#+nil ;; two different solutions
(quadratic-roots 1d0 2d0 -3d0)
#+nil ;; one solution
(quadratic-roots 1d0 0d0 -2d0)
#+nil ;; undefined result
(handler-case 
    (quadratic-roots 0d0 0d0 1d0)
  (no-solution () 'no))

(defmethod ray-sphere-intersection-length ((ray ray) center radius)
  (declare (vec center)
	   (double-float radius)
	   (values double-float &optional))
  ;; (c-x)^2=r^2 defines the sphere, substitute x with the rays p+alpha a,
  ;; the raydirection should have length 1, solve the quadratic equation,
  ;; the distance between the two solutions is the distance that the ray
  ;; travelled through the sphere
  (check-direction-norm ray)
  (with-slots ((start vector::start) (direction vector::direction)) ray
    (let* ((l (v- center start))
	   (c (- (v. l l) (* radius radius)))
	   (b (* -2d0 (v. l direction))))
      (handler-case 
	  (multiple-value-bind (x1 x2)
	      (quadratic-roots 1d0 b c)
	    (abs (- x1 x2)))
	(one-solution () 0d0)
	(no-solution () 0d0)))))

#+nil
(ray-sphere-intersection-length (v 0d0 .1d0 -12d0) (v 0d0 0d0 1d0) (v) 3d0)

(defmethod ray-spheres-intersection ((ray ray) (model sphere-algebraic-model)
				     illuminated-sphere-index)
  (declare (fixnum illuminated-sphere-index)
	   (values double-float &optional))
  (with-slots (centers-mm radii-mm) model
    (let ((sum 0d0))
      (loop for c in centers-mm and r in radii-mm and i from 0 do
	   (unless (eq i illuminated-sphere-index)
	    (incf sum (ray-sphere-intersection-length ray c r))))
      sum)))





