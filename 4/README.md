Воостановить дерево каталогов и пустых файлов:

```
/var/tmp/temp/file1.c

/var/tmp/file.ext

/var/tmp/temp/
```

---

Решение на баше в файле [script.sh](script.sh).  

PS Для windows - всего одна команда штатной утилитой `robocopy` с ключом `/create`:  
```text
Creates a directory tree and zero-length files only
```
