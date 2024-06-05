function showdir

if isunix
   ! open .
else
   winopen(pwd)
end