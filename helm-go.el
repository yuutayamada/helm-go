;;; helm-go.el --- Show Go's functions and types by helm

;; Copyright (C) 2013 by Yuta Yamada

;; Author: Yuta Yamada <cokesboy"at"gmail.com>
;; URL: https://github.com/yuutayamada/helm-go
;; Version: 0.0.1
;; Package-Requires: ((helm "1.0") (helm-ag-r "20131116") (go-mode "0"))
;; Keywords: golang

;;; License:
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; Commentary:

;;; Code:

(eval-when-compile (require 'cl))
(require 'go-mode)
(require 'helm-ag-r)

(defvar helm-go-cache-file "~/.helm-go-cache")
(defvar helm-go-buffer-name "*helm-go*")

(defvar helm-go-save-function
  (lambda (package)
    (format
     "godoc %s | grep \"^(func|type)\" | sed 's|\\(^[a-z]*\\)|%s:\\1|' >> %s"
     package package helm-go-cache-file)))

(defun helm-go-show-godoc (line)
  "Show godoc and move to specified function or type of the LINE."
  (lexical-let
      ((pkg-and-func (split-string line ":"))
       (buffer       (format "%s|godoc" helm-go-buffer-name)))
    (pop-to-buffer (get-buffer-create buffer))
    (read-only-mode 0)
    (erase-buffer)
    (shell-command
     (format "godoc %s" (car pkg-and-func)) buffer)
    (read-only-mode t)
    (when (string-match
           "\\(^\\(func\\|type\\) [a-zA-Z]+\\)" (nth 1 pkg-and-func))
      (search-forward-regexp
       (format "%s(" (match-string 0 (nth 1 pkg-and-func))) nil t))
    (view-mode t)))

;;;###autoload
(defun helm-go ()
  "Show Go's functions and types."
  (interactive)
  (if (file-exists-p helm-go-cache-file)
      (helm-ag-r-pype
       (format "cat %s" helm-go-cache-file)
       '((name . "helm-go")
         (action . (("Show godoc" . helm-go-show-godoc))))
       helm-go-buffer-name)
    (when (y-or-n-p "Cache file doesn't exists, create new one?")
      (helm-go-save-documents))))

(defun helm-go-save-documents ()
  (interactive)
  (lexical-let
      ((packages (append (go-packages)
                         (list "builtin")))
       (make-script
        (lambda (packages)
          (loop with scripts = '()
                for pkg in packages
                collect (funcall helm-go-save-function pkg) into scripts
                finally return (format
                                "%s" (mapconcat 'identity scripts ";"))))))
    (shell-command (funcall make-script packages))))

(defun helm-go-show-packages ()
  (interactive)
  (helm :sources
        `(((name . "Go packages")
           (candidates . (lambda () (append (go-packages) (list "builtin"))))
           (action .     (lambda (arg)
                           (shell-command
                            (format "godoc %s" arg)
                            (format "%s|godoc" helm-go-buffer-name))))))
        :prompt "helm-go: "
        :buffer "*helm-go*"
        :candidates-in-buffer t))

;;;###autoload
(defun helm-go-update-doc ()
  (interactive)
  (when (y-or-n-p "Update cache file?")
    (when (file-exists-p helm-go-cache-file)
      (delete-file helm-go-cache-file))
    (helm-go-save-documents)))

(provide 'helm-go)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; helm-go.el ends here
