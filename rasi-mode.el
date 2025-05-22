;;; rasi-mode.el --- Major mode for editing RASI files.

;; Copyright © 2025, by Ta Quang Trung

;; Author: Ta Quang Trung
;; Version: 0.0.1
;; Created: 22 May, 2025
;; Keywords: languages
;; Homepage: https://github.com/taquangtrung/emacs-rasi-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs major mode for editing RASI files.

;; Features:
;; - Syntax highlighting
;; - Automatic code indentation

;; Installation:
;; - Automatic package installation from Melpa.
;; - Manual installation by putting the `rasi-mode.el' file in Emacs' load path.

;;; Code:

(require 'rx)

(defconst rasi-special-constants
  '("true"
    "false")
  "List of RASI constants.")

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax highlighting

(defvar rasi-syntax-table
  (let ((syntax-table (make-syntax-table)))
    ;; C++ style comment "// ..."
    (modify-syntax-entry ?\/ ". 124" syntax-table)
    (modify-syntax-entry ?* ". 23b" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)
    ;; Punctuation
    (modify-syntax-entry ?= "." syntax-table)
    syntax-table)
  "Syntax table for `rasi-mode'.")

(defvar rasi-special-constants-regexp
  (concat
   (rx symbol-start)
   (regexp-opt rasi-special-constants t)
   (rx symbol-end))
  "Regular expression to match special RASI constant.")

(defun rasi-match-regexp (regexp bound)
  "Generic regular expression matching wrapper for REGEXP until a BOUND position."
  (re-search-forward regexp bound t nil))

(defun rasi-match-global-selector-name (bound)
  "Search the buffer forward until BOUND to match selector names."
  (rasi-match-regexp "[[:space:]]*\\(\\*\\)[[:space:]]*{" bound))

(defun rasi-match-selector-name (bound)
  "Search the buffer forward until BOUND to match selector names."
  (rasi-match-regexp
   (concat "\\([a-zA-Z0-9_,* -]+\\)[[:space:]]*{")
   bound))

(defun rasi-match-property-name (bound)
  "Search the buffer forward until BOUND to match property names."
  (rasi-match-regexp
   (concat (rx symbol-start)
           "\\([a-zA-Z0-9_-]+\\)"
           (rx symbol-end)
           "[[:space:]]*:")
   bound))

(defun rasi-match-special-value-name (bound)
  "Search the buffer forward until BOUND to match a special value names."
  (rasi-match-regexp
   (concat "@"
           (rx symbol-start)
           "\\([a-zA-Z0-9_-]+\\)"
           (rx symbol-end))
   bound))

(defconst rasi-font-locks
  (list
   `(,rasi-special-constants-regexp . font-lock-constant-face)
   '(rasi-match-selector-name (1 font-lock-type-face))
   '(rasi-match-property-name (1 font-lock-variable-name-face))
   '(rasi-match-special-value-name (1 font-lock-builtin-face)))
  "Font lock keywords of `rasi-mode'.")

;;;;;;;;;;;;;;;;;;
;;; Indentation

(defun rasi-indent-line (&optional indent)
  "Indent the current line according to the RASI syntax, or supply INDENT."
  (interactive "P")
  (let ((pos (- (point-max) (point)))
        (indent (or indent (rasi--calculate-indentation)))
        (shift-amount nil)
        (beg (progn (beginning-of-line) (point))))
    (skip-chars-forward " \t")
    (if (null indent)
        (goto-char (- (point-max) pos))
      (setq shift-amount (- indent (current-column)))
      (unless (zerop shift-amount)
        (delete-region beg (point))
        (indent-to indent))
      (when (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos))))))

(defun rasi--calculate-indentation ()
  "Calculate the indentation of the current line."
  (let (indent)
    (save-excursion
      (back-to-indentation)
      (let* ((ppss (syntax-ppss))
             (depth (car ppss))
             (paren-start-pos (cadr ppss))
             (base (* tab-width depth)))
        (unless (= depth 0)
          (setq indent base)
          (cond ((looking-at "\s*[})]")
                 ;; closing a block or a parentheses pair
                 (setq indent (- base tab-width)))
                ((looking-at "\s*:=")
                 ;; indent for multiple-line assignment
                 (setq indent (+ base (* 2 tab-width))))
                ((looking-back "\s*:=\s*\n\s*")
                 ;; indent for multiple-line assignment
                 (setq indent (+ base (* 2 tab-width))))))))
    indent))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Major mode settings

;;;###autoload
(define-derived-mode rasi-mode prog-mode
  "rasi-mode"
  "Major mode for editing RASI document language."
  :syntax-table rasi-syntax-table

  ;; Syntax highlighting
  (setq font-lock-defaults '(rasi-font-locks))

  ;; Indentation
  (setq-local indent-tabs-mode nil)
  (setq-local indent-line-function #'rasi-indent-line)

  ;; Set comment command
  (setq-local comment-start "//")
  (setq-local comment-end "")
  (setq-local comment-multi-line nil)
  (setq-local comment-use-syntax t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rasi\\'" . rasi-mode))

;; Finally export the `rasi-mode'
(provide 'rasi-mode)

;;; rasi-mode.el ends here
