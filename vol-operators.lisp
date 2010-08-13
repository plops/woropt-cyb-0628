(in-package :vol)

(defun .*2 (vola volb)
  (declare ((simple-array (complex my-float) 2) vola volb)
	   (values (simple-array (complex my-float) 2) &optional))
  (let ((result (make-array (array-dimensions vola)
			    :element-type (array-element-type vola))))
   (destructuring-bind (y x)
       (array-dimensions vola)
     (do-rectangle (j i 0 y 0 x)
       (setf (aref result j i)
	     (* (aref vola j i)
		(aref volb j i)))))
   result))

(defun .+2 (vola volb)
  (declare ((simple-array (complex my-float) 2) vola volb)
	   (values (simple-array (complex my-float) 2) &optional))
  (let ((result (make-array (array-dimensions vola)
			    :element-type (array-element-type vola))))
   (destructuring-bind (y x)
       (array-dimensions vola)
     (do-rectangle (j i 0 y 0 x)
       (setf (aref result j i)
	     (+ (aref vola j i)
		(aref volb j i)))))
   result))

(defun .* (vola volb &optional volb-start)
  "Elementwise multiplication of VOLA and VOLB. Both volumes must have
the same dimensions or VOLB must be smaller in all dimensions. In the
latter case a vec-i has to be supplied in VOLB-START to define the
relative position of VOLB inside VOLA."
  (declare ((simple-array (complex my-float) 3) vola volb)
	   ((or null vec-i) volb-start)
	   (values (simple-array (complex my-float) 3) &optional))
  (let ((result (make-array (array-dimensions volb)
			    :element-type '(complex my-float))))
   (destructuring-bind (z y x)
       (array-dimensions vola)
     (destructuring-bind (zz yy xx)
	 (array-dimensions volb)
       (if volb-start
	   ;; fill the result with volb multiplied by the
	   ;; corresponding values from the bigger vola
	   (let ((sx (vec-i-x volb-start))
		 (sy (vec-i-y volb-start))
		 (sz (vec-i-z volb-start)))
	     (unless (and (<= zz (+ z sz))
			  (<= yy (+ y sy))
			  (<= xx (+ x sx)))
	       (error "VOLB isn't contained in VOLA when shifted by VOLB-START. ~a" 
		      (list zz (+ z sz))))
	     (do-box (k j i 0 zz 0 yy 0 xx)
	       (setf (aref result k j i)
		     (* (aref volb k j i)
			(aref vola (+ k sz) (+ j sy) (+ i sx))))))
	   (progn 
	     (unless (and (= z zz) (= y yy) (= x xx))
	       (error "volumes don't have the same size, maybe you can supply a start vector."))
	     (do-box (k j i 0 z 0 y 0 x)
	       (setf (aref result k j i)
		     (* (aref vola k j i)
			(aref volb k j i))))))))
   result))

(defun .+ (vola volb &optional (volb-start (make-vec-i)))
  (declare ((simple-array (complex my-float) 3) vola volb)
	   (vec-i volb-start)
	   (values (simple-array (complex my-float) 3) &optional))
  (let ((result (make-array (array-dimensions volb)
			    :element-type '(complex my-float))))
    (destructuring-bind (z y x)
	(array-dimensions volb)
      (let ((sx (vec-i-x volb-start))
	    (sy (vec-i-y volb-start))
	    (sz (vec-i-z volb-start)))
	(do-box (k j i 0 z 0 y 0 x)
	  (setf (aref result k j i)
		(+ (aref vola (+ k sz) (+ j sy) (+ i sx))
		   (aref volb k j i))))))
    result))

(defun .- (vola volb &optional (volb-start (make-vec-i)))
  (declare ((simple-array (complex my-float) 3) vola volb)
	   (vec-i volb-start)
	   (values (simple-array (complex my-float) 3) &optional))
  (let ((result (make-array (array-dimensions volb)
			    :element-type '(complex my-float))))
    (destructuring-bind (z y x)
	(array-dimensions volb)
      (let ((sx (vec-i-x volb-start))
	    (sy (vec-i-y volb-start))
	    (sz (vec-i-z volb-start)))
	(do-box (k j i 0 z 0 y 0 x)
	  (setf (aref result k j i)
		(- (aref vola (+ k sz) (+ j sy) (+ i sx))
		   (aref volb k j i))))))
    result))

(declaim (ftype (function (my-float (simple-array (complex my-float) 3))
			  (values (simple-array (complex my-float) 3) &optional))
		s*))
(defun s* (s vol)
  (let* ((a (sb-ext:array-storage-vector vol))
	 (n (length a)))
    (dotimes (i n)
      (setf (aref a i) (* s (aref a i)))))
  vol)

(defun s*2 (s vol)
  (declare (my-float s)
	   ((simple-array (complex my-float) 2) vol)
	   (values (simple-array (complex my-float) 2) &optional))
  (let* ((a (sb-ext:array-storage-vector vol))
	 (n (length a)))
    (dotimes (i n)
      (setf (aref a i) (* s (aref a i)))))
  vol)


(defun mean-realpart (a)
  "Calculate the average value over all the samples in volume A."
  (declare ((simple-array (complex my-float) *) a)
	   (values my-float &optional))
  (let* ((a1 (sb-ext:array-storage-vector a))
	 (sum zero)
	 (n (length a1)))
    (dotimes (i n)
      (incf sum (realpart (aref a1 i))))
    (/ sum n)))