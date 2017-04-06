(ql:quickload 'ltk)
(use-package :ltk)

(setf *random-state* (make-random-state t))

(defun zeros (x) (loop for i from 1 to x collect 0))

(defun int-coords (index &optional (maxx 20)) (list (mod index maxx) (floor (/ index maxx))))

(defun grid-coords (index &optional (maxx 20) &aux (coords (int-coords index maxx)))
  (mapcar #'1+ (list (* (car coords) 25) (* (cadr coords) 25)
		     (* (1+ (car coords)) 25) (* (1+ (cadr coords)) 25))))

(defun snake-decf-life (life-vals)
  (loop for i upto (1- (length life-vals))
	if (> (nth i life-vals) 0) do (decf (nth i life-vals))
	if (< (nth i life-vals) 0) do (incf (nth i life-vals))
	finally (return life-vals)))

(defun create-grid (canvas life-vals)
  (loop for life in life-vals for i from 0
	collect (apply #'create-rectangle canvas (grid-coords i))))

(defun draw-grid (canvas grid life-vals)
  (loop for life in life-vals for i from 0
	do (itemconfigure canvas (nth i grid) :fill (if (zerop life) 'white
						      (if (> life 0) 'green 'blue)))))

(defun index-move (direction) (ccase direction (up -20) (left -1) (right 1) (down 20)))

(defun new-food-index (life-vals)
  (let ((p (loop for life in life-vals for i from 0 if (zerop life) collect i)))
    (nth (random (length p)) p)))

(defun move-food (canvas food old-index life-vals &aux (new-index (new-food-index life-vals)))
  (let ((deltas (mapcar #'- (grid-coords new-index) (grid-coords old-index))))
  (itemmove canvas food (car deltas) (cadr deltas))) new-index)

(defun check-boundaries (index next-move)
  (or (and (< index 20) (equal next-move 'up))
      (and (> index 379) (equal next-move 'down))
      (and (= (mod index 20) 0) (equal next-move 'left))
      (and (= (mod index 20) 19) (equal next-move 'right))))

(defun lose (canvas)
  (create-text canvas 50 50 (nth (random 3) '("Wow, that's really sad."
					      "Well, that's just sad."
					      "Bad snake award, 2016-17!"))))

(defun snake (&optional (life-vals (zeros 400)))
  (with-ltk ()
	    (let* ((c (make-instance 'canvas :height 501 :width 501))
		   (grid-field (create-grid c life-vals))
		   (next-move 'right) (index 20) (s-length 3)
		   (next-move2 'left) (index2 379) (s-length2 -3)
		   (food-index (new-food-index life-vals))
		   (food (apply #'create-oval c (grid-coords food-index))))
	      (bind c "<KeyPress-q>"
		    (lambda (evt) (declare (ignore evt))
		      (exit-wish)))
	      (bind c "<KeyPress-r>"
		    (lambda (evt) (declare (ignore evt))
		      (create-grid c life-vals)))
	      (bind c "<KeyPress-Up>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move 'down) (setf next-move 'up))))
	      (bind c "<KeyPress-Left>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move 'right) (setf next-move 'left))))
	      (bind c "<KeyPress-Right>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move 'left) (setf next-move 'right))))
	      (bind c "<KeyPress-Down>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move 'up) (setf next-move 'down))))
	      (bind c "<KeyPress-w>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move2 'down) (setf next-move2 'up))))
	      (bind c "<KeyPress-a>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move2 'right) (setf next-move2 'left))))
	      (bind c "<KeyPress-d>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move2 'left) (setf next-move2 'right))))
	      (bind c "<KeyPress-s>"
		    (lambda (evt) (declare (ignore evt))
		      (unless (equal next-move2 'up) (setf next-move2 'down))))
	      (bind c "<ButtonPress-1>"
		    (lambda (evt) (format t "(~A, ~A)" (event-x evt) (event-y evt))))

	      (itemconfigure c food :fill 'red)
	      (pack c)
	      (force-focus c)
	      (loop while t
		    do (process-events)
		    when (check-boundaries index next-move) return nil
		    when (check-boundaries index2 next-move2) return nil
		    do (incf index (index-move next-move))
		    do (incf index2 (index-move next-move2))
		    when (= index food-index)
		    do (progn (incf s-length) (setf food-index (move-food c food index life-vals)))
		    when (= index2 food-index)
		    do (progn (decf s-length2) (setf food-index (move-food c food index2 life-vals)))
		    unless (or (= index food-index) (= index2 food-index))
		    do (setf life-vals (snake-decf-life life-vals))
		    do (process-events)
		    unless (zerop (nth index life-vals)) return nil
		    unless (zerop (nth index2 life-vals)) return nil
		    do (setf (nth index life-vals) s-length)
		    do (setf (nth index2 life-vals) s-length2)
		    do (draw-grid c grid-field life-vals) 
		    do (sleep 1/8))
	      (lose c))))

(snake)
