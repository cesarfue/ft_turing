NAME    = ft_turing
SRCDIR  = src
SRCS    = $(SRCDIR)/main.ml
OCAMLFIND = ocamlfind
OCAMLOPT  = ocamlopt
PACKAGES  = yojson
FLAGS     = -package $(PACKAGES) -linkpkg

all: $(NAME)

$(NAME):
	$(OCAMLFIND) $(OCAMLOPT) $(FLAGS) $(SRCS) -o $(NAME)

clean:
	rm -f $(SRCDIR)/*.cmi $(SRCDIR)/*.cmx $(SRCDIR)/*.o

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re
