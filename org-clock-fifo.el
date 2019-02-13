;;; org-clock-fifo.el -- Write org-clock status to a FIFO.

;; Copyright (C) 2019 Peter Jones <pjones@devalot.com>

;; Author: Peter Jones <pjones@devalot.com>
;; Homepage: https://github.com/pjones/org-clock-fifo
;; Package-Requires: ((emacs "24.4"))
;; Version: 0.1.0
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; This file defines a global minor mode called `org-clock-fifo-mode'.
;;
;; When active, this mode will write `org-clock' status messages to a
;; FIFO, creating the file if necessary.  You can then have some other
;; tool, say a desktop panel, read the file to get the latest status.

;;; License:
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Code:
(require 'org-clock)

(defcustom org-clock-fifo-filename
  (concat (file-name-as-directory user-emacs-directory) "org-clock-fifo")
  "The file name to use for the FIFO."
  :group 'org-clock
  :type 'string)

(defvar org-clock-fifo-timer nil
  "Timer used to update the FIFO.")

(defun org-clock-fifo-update ()
  "Update the FIFO."
  (unless (file-exists-p org-clock-fifo-filename)
    (call-process "mkfifo" nil nil nil org-clock-fifo-filename))
  (let ((inhibit-message t)
        (msg (if (org-clocking-p)
                 (substring-no-properties org-mode-line-string)
               "")))
    (with-temp-buffer
      (insert (concat msg "\n"))
      (write-region nil nil org-clock-fifo-filename t)))
  (if (and (null org-clock-fifo-timer) (org-clocking-p))
      (setq org-clock-fifo-timer
            (run-at-time t 10 #'org-clock-fifo-update))
    (unless (org-clocking-p)
      (if org-clock-fifo-timer (cancel-timer org-clock-fifo-timer))
      (setq org-clock-fifo-timer nil))))

(define-minor-mode org-clock-fifo-mode
  "A minor mode that writes `org-clock' status information to a FIFO."
  :global t
  (let ((hooks '( org-clock-in-hook
                  org-clock-out-hook
                  org-clock-cancel-hook )))
    (if org-clock-fifo-mode
        (progn
          (dolist (hook hooks)
            (add-hook hook #'org-clock-fifo-update))
          (org-clock-fifo-update))
      (dolist (hook hooks)
        (remove-hook hook #'org-clock-fifo-update)))))

(provide 'org-clock-fifo)
;;; org-clock-fifo.el ends here
